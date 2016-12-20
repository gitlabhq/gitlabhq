/* global Flash */

/**
 * In each pipelines table we have a mini pipeline graph for each pipeline.
 *
 * When we click in a pipeline stage, we need to make an API call to get the
 * builds list to render in a dropdown.
 *
 * The container should be the table element.
 *
 * The stage icon clicked needs to have the following HTML structure:
 * <div>
 *   <button class="dropdown js-builds-dropdown-button"></button>
 *   <div class="js-builds-dropdown-container"></div>
 * </div>
 */
(() => {
  class MiniPipelineGraph {
    constructor(opts = {}) {
      this.container = opts.container || '';
      this.dropdownListSelector = '.js-builds-dropdown-container';
      this.getBuildsList = this.getBuildsList.bind(this);

      this.bindEvents();
    }

    /**
     * Adds and removes the event listener.
     */
    bindEvents() {
      const dropdownButtonSelector = 'button.js-builds-dropdown-button';

      $(this.container).off('click', dropdownButtonSelector, this.getBuildsList);
      $(this.container).on('click', dropdownButtonSelector, this.getBuildsList);
    }

    /**
     * For the clicked stage, renders the given data in the dropdown list.
     *
     * @param  {HTMLElement} stageContainer
     * @param  {Object} data
     */
    renderBuildsList(stageContainer, data) {
      const dropdownContainer = stageContainer.parentElement.querySelector(
        `${this.dropdownListSelector} .js-builds-dropdown-list`,
      );

      dropdownContainer.innerHTML = data;
    }

    /**
     * For the clicked stage, gets the list of builds.
     *
     * @param  {Object} e
     * @return {Promise}
     */
    getBuildsList(e) {
      const endpoint = e.currentTarget.dataset.stageEndpoint;

      return $.ajax({
        dataType: 'json',
        type: 'GET',
        url: endpoint,
        beforeSend: () => {
          this.renderBuildsList(e.currentTarget, '');
          this.toggleLoading(e.currentTarget);
        },
        success: (data) => {
          this.toggleLoading(e.currentTarget);
          this.renderBuildsList(e.currentTarget, data.html);
        },
        error: () => new Flash('An error occurred while fetching the builds.', 'alert'),
      });
    }

    /**
     * Toggles the visibility of the loading icon.
     *
     * @param  {HTMLElement} stageContainer
     * @return {type}
     */
    toggleLoading(stageContainer) {
      stageContainer.parentElement.querySelector(
        `${this.dropdownListSelector} .js-builds-dropdown-loading`,
      ).classList.toggle('hidden');
    }
  }

  window.gl = window.gl || {};
  window.gl.MiniPipelineGraph = MiniPipelineGraph;
})();
