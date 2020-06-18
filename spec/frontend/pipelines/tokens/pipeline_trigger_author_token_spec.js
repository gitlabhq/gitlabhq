import Api from '~/api';
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineTriggerAuthorToken from '~/pipelines/components/tokens/pipeline_trigger_author_token.vue';
import { users } from '../mock_data';

describe('Pipeline Trigger Author Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

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
  };

  const createComponent = (options, data) => {
    wrapper = shallowMount(PipelineTriggerAuthorToken, {
      propsData: {
        ...defaultProps,
      },
      data() {
        return {
          ...data,
        };
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(users);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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
      createComponent({ stubs }, { loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent({ stubs }, { loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('shows trigger authors correctly', () => {
    beforeEach(() => {});

    it('renders all trigger authors', () => {
      createComponent({ stubs }, { users, loading: false });

      // should have length of all users plus the static 'Any' option
      expect(findAllFilteredSearchSuggestions()).toHaveLength(users.length + 1);
    });

    it('renders only the trigger author searched for', () => {
      createComponent(
        { stubs },
        {
          users: [
            { name: 'Arnold', username: 'admin', state: 'active', avatar_url: 'avatar-link' },
          ],
          loading: false,
        },
      );

      expect(findAllFilteredSearchSuggestions()).toHaveLength(2);
    });
  });
});
