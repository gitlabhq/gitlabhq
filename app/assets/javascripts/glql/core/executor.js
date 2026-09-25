import { assign } from 'lodash-es';
import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';
import { EXECUTION_QUEUE_DASHBOARD, EXECUTION_QUEUE_DEFAULT } from '../constants';
import TaskQueue from '../utils/task_queue';
import { extractGroupOrProject } from '../utils/common';

// Embedded blocks run one at a time, a readiness commitment from the GLQL beta review
// (https://gitlab.com/gitlab-org/gitlab/-/issues/517546): popular descriptions with many
// blocks hit Postgres from every viewer. Dashboards have few viewers and bounded panels.
const CONCURRENCY_LIMITS = {
  [EXECUTION_QUEUE_DEFAULT]: 1,
  [EXECUTION_QUEUE_DASHBOARD]: 6,
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
  static taskQueues = {};

  static taskQueue(name = EXECUTION_QUEUE_DEFAULT) {
    // Unknown names share the default queue rather than silently getting a queue of their own.
    const queue = Object.hasOwn(CONCURRENCY_LIMITS, name) ? name : EXECUTION_QUEUE_DEFAULT;

    if (!Executor.taskQueues[queue]) {
      Executor.taskQueues[queue] = new TaskQueue(CONCURRENCY_LIMITS[queue]);
    }

    return Executor.taskQueues[queue];
  }

  init(client) {
    const searchParams = new URLSearchParams(extractGroupOrProject());

    this.#client = client || createDefaultClient({}, { path: `/api/glql?${searchParams}` });

    return this;
  }

  async execute(query, variables = {}, { queue, signal } = {}) {
    return this.#enqueue(
      query,
      assign(
        ...(await Promise.all(
          Object.entries(variables).map(async ([key, { type, value }]) => ({
            [key]: isSubquery(value) ? await this.#executeSubquery(value, type) : value,
          })),
        )),
      ),
      { queue, signal },
    );
  }

  async #executeSubquery(query, variableType) {
    return transformGIDToString(resolveToScalar(await this.#execute(query)), variableType);
  }

  async #execute(query, variables = {}) {
    const { data } = await this.#client.query({
      query: gql`
        ${query}
      `,
      variables,
    });

    return data;
  }

  async #enqueue(query, variables, { queue, signal } = {}) {
    return Executor.taskQueue(queue).enqueue(() => this.#execute(query, variables), { signal });
  }
}

export const execute = async (query, variables = {}, options = {}) => {
  return new Executor().init().execute(query, variables, options);
};
