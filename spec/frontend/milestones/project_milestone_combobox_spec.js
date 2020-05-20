import { milestones as projectMilestones } from './mock_data';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import MilestoneCombobox from '~/milestones/project_milestone_combobox.vue';
import { GlNewDropdown, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';

const TEST_SEARCH_ENDPOINT = '/api/v4/projects/8/search';

const extraLinks = [
  { text: 'Create new', url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/-/milestones/new' },
  { text: 'Manage milestones', url: '/h5bp/html5-boilerplate/-/milestones' },
];

const preselectedMilestones = [];
const projectId = '8';

describe('Milestone selector', () => {
  let wrapper;
  let mock;

  const findNoResultsMessage = () => wrapper.find({ ref: 'noResults' });

  const factory = (options = {}) => {
    wrapper = shallowMount(MilestoneCombobox, {
      ...options,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    mock.onGet('/api/v4/projects/8/milestones').reply(200, projectMilestones);

    factory({
      propsData: {
        projectId,
        preselectedMilestones,
        extraLinks,
      },
    });
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the dropdown', () => {
    expect(wrapper.find(GlNewDropdown)).toExist();
  });

  it('renders additional links', () => {
    const links = wrapper.findAll('[href]');
    links.wrappers.forEach((item, idx) => {
      expect(item.text()).toBe(extraLinks[idx].text);
      expect(item.attributes('href')).toBe(extraLinks[idx].url);
    });
  });

  describe('before results', () => {
    it('should show a loading icon', () => {
      const request = mock.onGet(TEST_SEARCH_ENDPOINT, {
        params: { search: 'TEST_SEARCH', scope: 'milestones' },
      });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);

      return wrapper.vm.$nextTick().then(() => {
        request.reply(200, []);
      });
    });

    it('should not show any dropdown items', () => {
      expect(wrapper.findAll('[role="milestone option"]')).toHaveLength(0);
    });

    it('should have "No milestone" as the button text', () => {
      expect(wrapper.find({ ref: 'buttonText' }).text()).toBe('No milestone');
    });
  });

  describe('with empty results', () => {
    beforeEach(() => {
      mock
        .onGet(TEST_SEARCH_ENDPOINT, { params: { search: 'TEST_SEARCH', scope: 'milestones' } })
        .reply(200, []);
      wrapper.find(GlSearchBoxByType).vm.$emit('input', 'TEST_SEARCH');
      return axios.waitForAll();
    });

    it('should display that no matching items are found', () => {
      expect(findNoResultsMessage().exists()).toBe(true);
    });
  });

  describe('with results', () => {
    let items;
    beforeEach(() => {
      mock
        .onGet(TEST_SEARCH_ENDPOINT, { params: { search: 'v0.1', scope: 'milestones' } })
        .reply(200, [
          {
            id: 41,
            iid: 6,
            project_id: 8,
            title: 'v0.1',
            description: '',
            state: 'active',
            created_at: '2020-04-04T01:30:40.051Z',
            updated_at: '2020-04-04T01:30:40.051Z',
            due_date: null,
            start_date: null,
            web_url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/-/milestones/6',
          },
        ]);
      wrapper.find(GlSearchBoxByType).vm.$emit('input', 'v0.1');
      return axios.waitForAll().then(() => {
        items = wrapper.findAll('[role="milestone option"]');
      });
    });

    it('should display one item per result', () => {
      expect(items).toHaveLength(1);
    });

    it('should emit a change if an item is clicked', () => {
      items.at(0).vm.$emit('click');
      expect(wrapper.emitted().change.length).toBe(1);
      expect(wrapper.emitted().change[0]).toEqual([[{ title: 'v0.1' }]]);
    });

    it('should not have a selecton icon on any item', () => {
      items.wrappers.forEach(item => {
        expect(item.find('.selected-item').exists()).toBe(false);
      });
    });

    it('should have a selecton icon if an item is clicked', () => {
      items.at(0).vm.$emit('click');
      expect(wrapper.find('.selected-item').exists()).toBe(true);
    });

    it('should not display a message about no results', () => {
      expect(findNoResultsMessage().exists()).toBe(false);
    });
  });
});
