import { GlButton, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_PER_PAGE } from '~/api';
import { sprintf } from '~/locale';
import TagSearch from '~/releases/components/tag_search.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';
import { createRefModule } from '~/ref/stores';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_PROJECT_ID = '1234';
const TAGS = [{ name: 'v1' }, { name: 'v2' }, { name: 'v3' }];

describe('releases/components/tag_search', () => {
  let store;
  let wrapper;
  let mock;

  const createWrapper = (propsData = {}) => {
    wrapper = mount(TagSearch, {
      store,
      propsData,
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          projectId: TEST_PROJECT_ID,
        }),
        ref: createRefModule(),
      },
    });

    store.state.editNew.release = {};

    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
  });

  afterEach(() => mock.restore());

  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findCreate = () => {
    const buttons = wrapper.findAllComponents(GlButton);
    return buttons.at(buttons.length - 1);
  };
  const findResults = () => wrapper.findAllComponents(GlDropdownItem);

  describe('init', () => {
    beforeEach(async () => {
      mock
        .onGet(`/api/v4/projects/${TEST_PROJECT_ID}/repository/tags`)
        .reply(HTTP_STATUS_OK, TAGS, { 'x-total': TAGS.length });

      createWrapper();

      await waitForPromises();
    });

    it('displays a set of results immediately', () => {
      findResults().wrappers.forEach((w, i) => expect(w.text()).toBe(TAGS[i].name));
    });

    it('has a disabled button', () => {
      const button = findCreate();
      expect(button.text()).toBe('Or type a new tag name');
      expect(button.props('disabled')).toBe(true);
    });

    it('has an empty search input', () => {
      expect(findSearch().props('value')).toBe('');
    });

    describe('searching', () => {
      const query = TEST_TAG_NAME;

      beforeEach(async () => {
        mock.reset();
        mock
          .onGet(`/api/v4/projects/${TEST_PROJECT_ID}/repository/tags`, {
            params: { search: query, per_page: DEFAULT_PER_PAGE },
          })
          .reply(HTTP_STATUS_OK, [], { 'x-total': 0 });

        findSearch().vm.$emit('input', query);

        await nextTick();
        await waitForPromises();
      });

      it('shows "No results found" when there are no results', () => {
        expect(wrapper.text()).toContain('No results found');
      });

      it('searches with the given input', () => {
        expect(mock.history.get[0].params.search).toBe(query);
      });

      it('emits the query', () => {
        expect(wrapper.emitted('change')).toEqual([[query]]);
      });
    });
  });

  describe('with query', () => {
    const query = TEST_TAG_NAME;

    beforeEach(async () => {
      mock
        .onGet(`/api/v4/projects/${TEST_PROJECT_ID}/repository/tags`, {
          params: { search: query, per_page: DEFAULT_PER_PAGE },
        })
        .reply(HTTP_STATUS_OK, TAGS, { 'x-total': TAGS.length });

      createWrapper({ query });

      await waitForPromises();
    });

    it('displays a set of results immediately', () => {
      findResults().wrappers.forEach((w, i) => expect(w.text()).toBe(TAGS[i].name));
    });

    it('has an enabled button', () => {
      const button = findCreate();
      expect(button.text()).toMatchInterpolatedText(sprintf('Create tag %{tag}', { tag: query }));
      expect(button.props('disabled')).toBe(false);
    });

    it('emits create event when button clicked', () => {
      findCreate().vm.$emit('click');
      expect(wrapper.emitted('create')).toEqual([[query]]);
    });

    it('has an empty search input', () => {
      expect(findSearch().props('value')).toBe(query);
    });
  });
});
