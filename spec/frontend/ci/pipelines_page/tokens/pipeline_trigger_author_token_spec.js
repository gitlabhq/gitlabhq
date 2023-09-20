import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import Api from '~/api';
import PipelineTriggerAuthorToken from '~/ci/pipelines_page/tokens/pipeline_trigger_author_token.vue';
import { users } from 'jest/ci/pipeline_details/mock_data';

describe('Pipeline Trigger Author Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const defaultProps = {
    config: {
      type: 'username',
      icon: 'user',
      title: 'Trigger author',
      dataType: 'username',
      unique: true,
      triggerAuthors: users,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const createComponent = (data) => {
    wrapper = shallowMount(PipelineTriggerAuthorToken, {
      propsData: {
        ...defaultProps,
      },
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="suggestions"></slot></div>`,
        }),
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(users);

    createComponent();
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  it('fetches and sets project users', () => {
    expect(Api.projectUsers).toHaveBeenCalled();

    expect(wrapper.vm.users).toEqual(users);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('displays loading icon correctly', () => {
    it('shows loading icon', () => {
      createComponent({ loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent({ loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('shows trigger authors correctly', () => {
    beforeEach(() => {});

    it('renders all trigger authors', () => {
      createComponent({ users, loading: false });

      // should have length of all users plus the static 'Any' option
      expect(findAllFilteredSearchSuggestions()).toHaveLength(users.length + 1);
    });

    it('renders only the trigger author searched for', () => {
      createComponent({
        users: [{ name: 'Arnold', username: 'admin', state: 'active', avatar_url: 'avatar-link' }],
        loading: false,
      });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(2);
    });
  });
});
