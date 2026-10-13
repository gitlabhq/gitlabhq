import { assign } from 'lodash-es';
import { gql } from '@apollo/client/core';
import createDefaultClient, { fetchPolicies } from '~/lib/graphql';
import { EXECUTION_QUEUE_DASHBOARD, EXECUTION_QUEUE_DEFAULT } from '../constants';
import ResultCache from '../utils/result_cache';
import TaskQueue from '../utils/task_queue';
import { extractGroupOrProject } from '../utils/common';

// Embedded blocks run one at a time, a readiness commitment from the GLQL beta review
// (https://gitlab.com/gitlab-org/gitlab/-/issues/517546): popular descriptions with many
// blocks hit Postgres from every viewer. Dashboards have few viewers and bounded panels.
// Only dashboards cache results: their panels remount on every tab switch and filter change.
const QUEUES = {
  [EXECUTION_QUEUE_DEFAULT]: { concurrency: 1, cache: false },
  [EXECUTION_QUEUE_DASHBOARD]: { concurrency: 8, cache: true },
};

export const resolveToScalar = (obj) => {
  const key0 = Object.keys(obj).filter((key) => key !== '__typename')[0];
  return typeof obj[key0] === 'object' ? resolveToScalar(obj[key0]) : obj[key0];
};

export const transformGIDToString = (data, type) => {
  // legacy epics expect the id to be the last part of the GID
  if (type === 'String') return data?.split('/').pop();
  return data;
};

// eslint-disable-next-line @gitlab/require-i18n-strings
const isSubquery = (value) => typeof value === 'string' && value.startsWith('query GLQL');

export default class Executor {
  #client;
  #results;
  static taskQueues = {};
  static sharedContexts = {};

  // Unknown names share the default queue rather than silently getting a queue of their own.
  static queueName(name = EXECUTION_QUEUE_DEFAULT) {
    return Object.hasOwn(QUEUES, name) ? name : EXECUTION_QUEUE_DEFAULT;
  }

  static taskQueue(name) {
    const queue = Executor.queueName(name);

    if (!Executor.taskQueues[queue]) {
      Executor.taskQueues[queue] = new TaskQueue(QUEUES[queue].concurrency);
    }

    return Executor.taskQueues[queue];
  }

  // One client per queue and endpoint path (which carries the page's group or project), so a
  // request no longer leaks a client. Apollo's own cache stays off: it keys rows by field and
  // arguments, but GLQL selects metrics and dimensions, so panels would overwrite each other's
  // rows. Queues that cache get a result cache keyed by the compiled query instead.
  static shared(name, { create = true } = {}) {
    const queue = Executor.queueName(name);
    const searchParams = new URLSearchParams(extractGroupOrProject());
    const config = { path: `/api/glql?${searchParams}`, fetchPolicy: fetchPolicies.NO_CACHE };
    const key = `${queue} ${config.path}`;

    if (!Executor.sharedContexts[key] && create) {
      Executor.sharedContexts[key] = {
        client: createDefaultClient({}, config),
        results: QUEUES[queue].cache ? new ResultCache() : undefined,
      };
    }

    return Executor.sharedContexts[key];
  }

  init(client, { results } = {}) {
    this.#client = client;
    this.#results = results;

    return this;
  }

  async execute(query, variables = {}, options = {}) {
    return this.#enqueue(
      query,
      assign(
        ...(await Promise.all(
          Object.entries(variables).map(async ([key, { type, value }]) => ({
            [key]: isSubquery(value) ? await this.#executeSubquery(value, type, options) : value,
          })),
        )),
      ),
      options,
    );
  }

  // Queued, cancelled and cached like the query it feeds, so a panel whose variables come from a
  // subquery costs no request on remount either.
  async #executeSubquery(query, variableType, options) {
    const data = await this.#enqueue(query, {}, options);

    return transformGIDToString(resolveToScalar(data), variableType);
  }

  async #execute(query, variables = {}, context = {}) {
    const { data } = await this.#client.query({
      query: gql`
        ${query}
      `,
      variables,
      context,
    });

    return data;
  }

  async #enqueue(query, variables, { queue, signal, tag, priority } = {}) {
    // The query compiles asynchronously, so the resolver may already be destroyed: a cache hit
    // must not revive it.
    if (signal?.aborted) throw signal.reason;

    const key = `${query}\n${JSON.stringify(variables)}`;
    const cached = this.#results?.read(key, tag);

    if (cached) return cached;

    // Claimed before waiting for a slot, so a reload meanwhile also drops the identical request
    // that this one would otherwise join.
    this.#results?.claim(key, tag);

    // Tasks wrap their outcome: the queue holds a slot until the returned value settles, and
    // joining a request another panel already started must not cost a second slot.
    const { result } = await Executor.taskQueue(queue).enqueue(
      async () => {
        // An identical request may have started while this one waited for a slot.
        const meanwhile = this.#results?.read(key, tag);
        if (meanwhile) return { result: meanwhile };

        if (!this.#results) return { result: await this.#execute(query, variables) };

        // Cached while pending, so a reload that forgets it also drops a request already running.
        // Apollo's deduplication is off because it would join a new request to that dropped one.
        const request = this.#execute(query, variables, { queryDeduplication: false });
        this.#results.set(key, request, tag);
        request.catch(() => this.#results.delete(key, request));

        return { result: await request };
      },
      { signal, priority },
    );

    return result;
  }
}

export const execute = async (query, variables = {}, options = {}) => {
  const { client, results } = Executor.shared(options.queue);

  return new Executor().init(client, { results }).execute(query, variables, options);
};

// Drops the cached results of every request that carried `tag`, so they are fetched again.
// Before the first request there is nothing to drop, and no client worth creating.
export const forget = (tag, queue) => {
  Executor.shared(queue, { create: false })?.results?.forget(tag);
};
