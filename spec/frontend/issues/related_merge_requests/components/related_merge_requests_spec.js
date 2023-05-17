import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import mockData from 'test_fixtures/issues/related_merge_requests.json';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import RelatedMergeRequests from '~/issues/related_merge_requests/components/related_merge_requests.vue';
import createStore from '~/issues/related_merge_requests/store/index';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';

const API_ENDPOINT = '/api/v4/projects/2/issues/33/related_merge_requests';

describe('RelatedMergeRequests', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    // put the fixture in DOM as the component expects
    document.body.innerHTML = `<div id="js-issuable-app"></div>`;
    document.getElementById('js-issuable-app').dataset.initial = JSON.stringify(mockData);

    mock = new MockAdapter(axios);
    mock.onGet(`${API_ENDPOINT}?per_page=100`).reply(HTTP_STATUS_OK, mockData, { 'x-total': 2 });

    wrapper = shallowMount(RelatedMergeRequests, {
      store: createStore(),
      propsData: {
        endpoint: API_ENDPOINT,
        projectNamespace: 'gitlab-org',
        projectPath: 'gitlab-ce',
      },
    });

    return axios.waitForAll();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('getAssignees', () => {
      const assignees = [{ name: 'foo' }, { name: 'bar' }];

      describe('when there is assignees array', () => {
        it('should return assignees array', () => {
          const mr = { assignees };

          expect(wrapper.vm.getAssignees(mr)).toEqual(assignees);
        });
      });

      it('should return an array with single assignee', () => {
        const mr = { assignee: assignees[0] };

        expect(wrapper.vm.getAssignees(mr)).toEqual([assignees[0]]);
      });

      it('should return empty array when assignee is not set', () => {
        expect(wrapper.vm.getAssignees({})).toEqual([]);
        expect(wrapper.vm.getAssignees({ assignee: null })).toEqual([]);
      });
    });
  });

  describe('template', () => {
    it('should render related merge request items', () => {
      expect(wrapper.find('[data-testid="count"]').text()).toBe('2');
      expect(wrapper.findAllComponents(RelatedIssuableItem)).toHaveLength(2);

      const props = wrapper.findAllComponents(RelatedIssuableItem).at(1).props();
      const data = mockData[1];

      expect(props.idKey).toEqual(data.id);
      expect(props.pathIdSeparator).toEqual('!');
      expect(props.pipelineStatus).toBe(data.head_pipeline.detailed_status);
      expect(props.assignees).toEqual([data.assignee]);
      expect(props.isMergeRequest).toBe(true);
      expect(props.confidential).toEqual(false);
      expect(props.title).toEqual(data.title);
      expect(props.state).toEqual(data.state);
      expect(props.createdAt).toEqual(data.created_at);
    });
  });
});
