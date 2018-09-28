import $ from 'jquery';
import flash from './flash';
import axios from './lib/utils/axios_utils';

/**
 * In each pipelines table we have a mini pipeline graph for each pipeline.
 *
 * When we click in a pipeline stage, we need to make an API call to get the
 * builds list to render in a dropdown.
 *
 * The container should be the table element.
 *
 * The stage icon clicked needs to have the following HTML structure:
 * <div class="dropdown">
 *   <button class="dropdown js-builds-dropdown-button" data-toggle="dropdown"></button>
 *   <div class="js-builds-dropdown-container dropdown-menu"></div>
 * </div>
 */

export default class MiniPipelineGraph {
  constructor(opts = {}) {
    this.container = opts.container || '';
    this.dropdownListSelector = '.js-builds-dropdown-container';
    this.getBuildsList = this.getBuildsList.bind(this);
  }

  /**
   * Adds the event listener when the dropdown is opened.
   * All dropdown events are fired at the .dropdown-menu's parent element.
   */
  bindEvents() {
    $(document)
      .off('shown.bs.dropdown', this.container)
      .on('shown.bs.dropdown', this.container, this.getBuildsList);
  }

  /**
   * When the user right clicks or cmd/ctrl + click in the job name
   * the dropdown should not be closed and the link should open in another tab,
   * so we stop propagation of the click event inside the dropdown.
   *
   * Since this component is rendered multiple times per page we need to guarantee we only
   * target the click event of this component.
   */
  stopDropdownClickPropagation() {
    $(document).on(
      'click',
      `${this.container} .js-builds-dropdown-list a.mini-pipeline-graph-dropdown-item`,
      (e) => {
        e.stopPropagation();
      },
    );
  }

  /**
   * For the clicked stage, renders the given data in the dropdown list.
   *
   * @param  {HTMLElement} stageContainer
   * @param  {Object} data
   */
  renderBuildsList(stageContainer, data) {
    const dropdownContainer = stageContainer.parentElement.querySelector(
      `${this.dropdownListSelector} .js-builds-dropdown-list ul`,
    );

    dropdownContainer.innerHTML = data;
  }

  /**
   * For the clicked stage, gets the list of builds.
   *
   * All dropdown events have a relatedTarget property,
   * whose value is the toggling anchor element.
   *
   * @param  {Object} e bootstrap dropdown event
   * @return {Promise}
   */
  getBuildsList(e) {
    const button = e.relatedTarget;
    const endpoint = button.dataset.stageEndpoint;

    this.renderBuildsList(button, '');
    this.toggleLoading(button);

    axios.get(endpoint)
      .then(({ data }) => {
        this.toggleLoading(button);
        this.renderBuildsList(button, data.html);
        this.stopDropdownClickPropagation();
      })
      .catch(() => {
        this.toggleLoading(button);
        if ($(button).parent().hasClass('open')) {
          $(button).dropdown('toggle');
        }
        flash('An error occurred while fetching the builds.', 'alert');
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
