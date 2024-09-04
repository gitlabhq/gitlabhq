import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';

export default class Executor {
  #client;

  init(client = createDefaultClient()) {
    this.#client = client;
    return this;
  }

  async execute(query) {
    const { data } = await this.#client.query({
      query: gql`
        ${query}
      `,
    });

    return data;
  }
}

export const execute = async (query) => {
  const executor = new Executor().init();
  return executor.execute(query);
};
