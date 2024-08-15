import { uniq } from 'lodash';
import { GitLabQueryLanguage as GlqlCompiler } from '@gitlab/query-language';
import { gql } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';
import { extractGroupOrProject, parseQueryText, parseFrontmatter } from '../utils/common';

/**
 * @import ApolloClient from '@apollo/client/core';
 */

const REQUIRED_QUERY_FIELDS = ['id', 'iid', 'title', 'webUrl', 'reference'];
const DEFAULT_DISPLAY_FIELDS = ['title'];

export default class Executor {
  #compiler;
  #client;
  #compiled;

  async #initCompiler() {
    const compiler = GlqlCompiler();
    const { group, project } = extractGroupOrProject();

    compiler.group = group;
    compiler.project = project;
    compiler.username = gon.current_username;
    await compiler.initialize();

    this.#compiler = compiler;
  }

  /**
   * Set the ApolloClient instance or use the default one
   *
   * @param {ApolloClient} client
   */
  #initClient(client) {
    this.#client = client || createDefaultClient();
  }

  /**
   * Initialize the Executor with the given ApolloClient instance
   *
   * @param {ApolloClient?} client
   * @returns {Promise<Executor>} this
   */
  async init(client) {
    await this.#initCompiler();
    this.#initClient(client);

    return this;
  }

  /**
   * Compile the given GLQL query with metadata
   *
   * @param {*} glqlQueryWithMetadata
   * @returns {Executor} this
   */
  compile(glqlQueryWithMetadata) {
    const { frontmatter, query } = parseQueryText(glqlQueryWithMetadata);
    const config = parseFrontmatter(frontmatter, { fields: DEFAULT_DISPLAY_FIELDS });

    this.#compiler.fields = uniq([...REQUIRED_QUERY_FIELDS, ...config.fields]);

    const limit = Math.min(100, parseInt(config.limit, 10) || 100);

    this.#compiled = { query: this.#compiler.compile('graphql', query, limit).output, config };

    return this;
  }

  /**
   * Execute the compiled query and return the result
   *
   * @returns {Promise<{ data: any, config: any }>}
   */
  async execute() {
    const { query, config } = this.#compiled;
    const { data } = await this.#client.query({
      query: gql`
        ${query}
      `,
    });

    return { data, config };
  }
}
