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
    constructor({ container }) {
      this.container = container;
      this.getBuildsList = this.getBuildsList.bind(this);

      this.bindEvents();
    }

    /**
     * Adds an removes the event listener.
     * TODO: Remove jQuery when we have a way to handle events properly.
     */
    bindEvents() {
      $(this.container).off('click', 'button.js-builds-dropdown-button', this.getBuildsList);
      $(this.container).on('click', 'button.js-builds-dropdown-button', this.getBuildsList);
    }

    /**
     * For the clicked stage, renders the received html in the sibiling
     * element with the `js-builds-dropdown-container` clas
     *
     * @param  {Element} stageContainer
     * @param  {Object} data
     */
    renderBuildsList(stageContainer, data) {
      const dropdownContainer = stageContainer.parentElement.querySelector('.js-builds-dropdown-container');

      dropdownContainer.innerHTML = data.html;
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
        success: data => this.renderBuildsList(e.currentTarget, data),
        error: () => new Flash('An error occurred while fetching the builds.', 'alert'),
      });
    }
  }

  window.gl = window.gl || {};
  window.gl.MiniPipelineGraph = MiniPipelineGraph;
})();
