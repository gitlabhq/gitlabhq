import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';
import TaskQueue from '../utils/task_queue';

const CONCURRENCY_LIMIT = 1;

export default class Executor {
  #client;
  static taskQueue;

  init(client = createDefaultClient({}, { path: '/api/glql' })) {
    Executor.taskQueue = Executor.taskQueue || new TaskQueue(CONCURRENCY_LIMIT);
    this.#client = client;
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
