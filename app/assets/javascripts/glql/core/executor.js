import { assign } from 'lodash';
import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';
import TaskQueue from '../utils/task_queue';
import { extractGroupOrProject } from '../utils/common';

const CONCURRENCY_LIMIT = 1;

export const resolveToScalar = (obj) => {
  const key0 = Object.keys(obj).filter((key) => key !== '__typename')[0];
  return typeof obj[key0] === 'object' ? resolveToScalar(obj[key0]) : obj[key0];
};

export const transformGIDToString = (data, type) => {
  // legacy epics expect the id to be the last part of the GID
  if (type === 'String') return data?.split('/').pop();
  return data;
};

export default class Executor {
  #client;
  static taskQueue;

  init(client) {
    Executor.taskQueue = Executor.taskQueue || new TaskQueue(CONCURRENCY_LIMIT);

    const searchParams = new URLSearchParams(extractGroupOrProject());

    this.#client = client || createDefaultClient({}, { path: `/api/glql?${searchParams}` });

    return this;
  }

  async execute(query, variables = []) {
    return this.#enqueue(
      query,
      assign(
        ...(await Promise.all(
          variables.map(async (variable) => ({
            [variable.key]: transformGIDToString(
              resolveToScalar(await this.#execute(variable.data)),
              variable.data_type,
            ),
          })),
        )),
      ),
    );
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

  async #enqueue(query, variables = {}) {
    return Executor.taskQueue.enqueue(() => this.#execute(query, variables));
  }
}

export const execute = async (query, variables = []) => {
  return new Executor().init().execute(query, variables);
};
