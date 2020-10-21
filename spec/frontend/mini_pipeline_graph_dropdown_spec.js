import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';
import waitForPromises from './helpers/wait_for_promises';

describe('Mini Pipeline Graph Dropdown', () => {
  preloadFixtures('static/mini_dropdown_graph.html');

  beforeEach(() => {
    loadFixtures('static/mini_dropdown_graph.html');
  });

  describe('When is initialized', () => {
    it('should initialize without errors when no options are given', () => {
      const miniPipelineGraph = new MiniPipelineGraph();

      expect(miniPipelineGraph.dropdownListSelector).toEqual('.js-builds-dropdown-container');
    });

    it('should set the container as the given prop', () => {
      const container = '.foo';

      const miniPipelineGraph = new MiniPipelineGraph({ container });

      expect(miniPipelineGraph.container).toEqual(container);
    });
  });

  describe('When dropdown is clicked', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should call getBuildsList', () => {
      const getBuildsListSpy = jest
        .spyOn(MiniPipelineGraph.prototype, 'getBuildsList')
        .mockImplementation(() => {});

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      expect(getBuildsListSpy).toHaveBeenCalled();
    });

    it('should make a request to the endpoint provided in the html', () => {
      const ajaxSpy = jest.spyOn(axios, 'get');

      mock.onGet('foobar').reply(200, {
        html: '',
      });

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      expect(ajaxSpy.mock.calls[0][0]).toEqual('foobar');
    });

    it('should not close when user uses cmd/ctrl + click', done => {
      mock.onGet('foobar').reply(200, {
        html: `<li>
          <a class="mini-pipeline-graph-dropdown-item" href="#">
            <span class="ci-status-icon ci-status-icon-failed"></span>
            <span>build</span>
          </a>
          <a class="ci-action-icon-wrapper js-ci-action-icon" href="#"></a>
        </li>`,
      });
      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      waitForPromises()
        .then(() => {
          document.querySelector('a.mini-pipeline-graph-dropdown-item').click();
        })
        .then(waitForPromises)
        .then(() => {
          expect($('.js-builds-dropdown-list').is(':visible')).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should close the dropdown when request returns an error', done => {
      mock.onGet('foobar').networkError();

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      setImmediate(() => {
        expect($('.js-builds-dropdown-tests .dropdown').hasClass('open')).toEqual(false);
        done();
      });
    });
  });
});
