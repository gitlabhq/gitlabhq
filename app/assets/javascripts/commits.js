import $ from 'jquery';
import { n__, s__ } from '~/locale';
import { createAlert } from '~/alert';
import createDefaultClient from '~/lib/graphql';
import { sanitize } from '~/lib/dompurify';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import commitDetailsQuery from '~/projects/commits/graphql/queries/commit_details.query.graphql';
import axios from './lib/utils/axios_utils';
import { localTimeAgo } from './lib/utils/datetime_utility';
import Pager from './pager';

const NEWLINE_CHAR = '&#x000A;';

const defaultClient = createDefaultClient();

const handleError = () =>
  createAlert({ message: s__('Commits|Something went wrong while fetching commit details') });

const fetchCommitDetails = async (commitId) => {
  const { projectFullPath: projectPath } = document.body.dataset;
  let commit;

  try {
    const { data } = await defaultClient.query({
      query: commitDetailsQuery,
      variables: { projectPath, ref: commitId },
    });
    commit = data?.project?.repository?.commit || {};
  } catch (error) {
    handleError();
  }

  return commit;
};

export default class CommitsList {
  constructor(limit = 0) {
    this.timer = null;

    this.$contentList = $('.content_list');

    Pager.init({ limit: parseInt(limit, 10), prepareData: this.processCommits.bind(this) });

    this.content = $('#commits-list');
    this.searchField = $('#commits-search');
    this.lastSearch = this.searchField.val();
    this.initSearch();
    this.initCommitDetails();
  }

  initSearch() {
    this.timer = null;
    this.searchField.on('keyup', () => {
      clearTimeout(this.timer);
      this.timer = setTimeout(this.filterResults.bind(this), 500);
    });
  }

  initCommitDetails() {
    this.content.on('click', '.js-toggle-button', ({ currentTarget }) =>
      this.handleToggleCommitDetails(currentTarget.dataset),
    );
  }

  async handleToggleCommitDetails({ commitId }) {
    const contentElement = this.content.find(`.js-toggle-content[data-commit-id="${commitId}"]`);
    if (!contentElement || contentElement.data('content-loaded')) return;
    contentElement.html(loadingIconForLegacyJS({ inline: true, size: 'sm' }));

    const commit = await fetchCommitDetails(commitId);
    let descriptionHtml = commit?.descriptionHtml;
    if (!descriptionHtml) {
      handleError();
      return;
    }

    if (descriptionHtml.startsWith(NEWLINE_CHAR))
      descriptionHtml = descriptionHtml.substring(NEWLINE_CHAR.length); // remove newline to avoid extra empty line before the description

    contentElement.html(sanitize(descriptionHtml));
    contentElement.attr('data-content-loaded', 'true');
  }

  filterResults() {
    const form = $('.commits-search-form');
    const search = this.searchField.val();
    if (search === this.lastSearch) return Promise.resolve();
    const commitsUrl = `${form.attr('action')}?${form.serialize()}`;
    this.content.addClass('gl-opacity-5');
    const params = form.serializeArray().reduce(
      (acc, obj) =>
        Object.assign(acc, {
          [obj.name]: obj.value,
        }),
      {},
    );

    return axios
      .get(form.attr('action'), {
        params,
      })
      .then(({ data }) => {
        this.lastSearch = search;
        this.content.html(data.html);
        this.content.removeClass('gl-opacity-5');

        // Change url so if user reload a page - search results are saved
        window.history.replaceState(
          {
            page: commitsUrl,
          },
          document.title,
          commitsUrl,
        );
      })
      .catch(() => {
        this.content.removeClass('gl-opacity-5');
        this.lastSearch = null;
      });
  }

  // Prepare loaded data.
  processCommits(data) {
    let processedData = data;
    const $processedData = $(processedData);
    const $commitsHeadersLast = this.$contentList.find('li.js-commit-header').last();
    const lastShownDay = $commitsHeadersLast.data('day');
    const $loadedCommitsHeadersFirst = $processedData.filter('li.js-commit-header').first();
    const loadedShownDayFirst = $loadedCommitsHeadersFirst.data('day');
    let commitsCount;

    // If commits headers show the same date,
    // remove the last header and change the previous one.
    if (lastShownDay === loadedShownDayFirst) {
      // Last shown commits count under the last commits header.
      commitsCount = $commitsHeadersLast.nextUntil('li.js-commit-header').find('li.commit').length;

      // Remove duplicate of commits header.
      processedData = $processedData.not(`li.js-commit-header[data-day='${loadedShownDayFirst}']`);

      // Update commits count in the previous commits header.
      commitsCount += Number(
        $(processedData).nextUntil('li.js-commit-header').first().find('li.commit').length,
      );

      $commitsHeadersLast
        .find('span.commits-count')
        .text(n__('%d commit', '%d commits', commitsCount));
    }

    localTimeAgo($processedData.find('.js-timeago').get());

    return processedData;
  }
}
