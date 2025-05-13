import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';
import TaskQueue from '../utils/task_queue';
import { extractGroupOrProject } from '../utils/common';
import { joinPaths } from '../../lib/utils/url_utility';

const CONCURRENCY_LIMIT = 1;

export default class Executor {
  #client;
  static taskQueue;

  init(client) {
    Executor.taskQueue = Executor.taskQueue || new TaskQueue(CONCURRENCY_LIMIT);

    const glqlPath =
      joinPaths(gon.relative_url_root || '', '/api/glql?') +
      new URLSearchParams(extractGroupOrProject());

    this.#client = client || createDefaultClient({}, { path: glqlPath });

    return this;
  }

  async execute(query) {
    const { data } = await Executor.taskQueue.enqueue(() =>
      this.#client.query({
        query: gql`
          ${query}
        `,
      }),
    );

    return data;
  }
}

export const execute = async (query) => {
  return new Executor().init().execute(query);
};
