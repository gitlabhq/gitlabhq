import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VerificationLevelToken from '~/ci/catalog/components/tokens/verification_level_token.vue';
import {
  VERIFICATION_LEVEL_SAAS_OPTIONS,
  VERIFICATION_LEVEL_SELF_MANAGED_OPTIONS,
} from '~/ci/catalog/constants';

describe('VerificationLevelToken', () => {
  let wrapper;

  const defaultProps = {
    config: { type: 'verificationLevel' },
    value: { data: '', operator: '=' },
  };

  const findToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(VerificationLevelToken, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFilteredSearchToken: {
          template: '<div><slot name="view"></slot><slot name="suggestions"></slot></div>',
        },
      },
    });
  };

  afterEach(() => {
    window.gon = {};
  });

  it('renders the filtered search token', () => {
    createComponent();

    expect(findToken().exists()).toBe(true);
  });

  describe('on SaaS', () => {
    beforeEach(() => {
      window.gon = { dot_com: true };
      createComponent();
    });

    it('renders SaaS verification level options', () => {
      const suggestions = findSuggestions();

      expect(suggestions).toHaveLength(VERIFICATION_LEVEL_SAAS_OPTIONS.length);

      VERIFICATION_LEVEL_SAAS_OPTIONS.forEach((option, index) => {
        expect(suggestions.at(index).props('value')).toBe(option.text);
        expect(suggestions.at(index).text()).toContain(option.text);
      });
    });
  });

  describe('on self-managed', () => {
    beforeEach(() => {
      window.gon = { dot_com: false };
      createComponent();
    });

    it('renders self-managed verification level options', () => {
      const suggestions = findSuggestions();

      expect(suggestions).toHaveLength(VERIFICATION_LEVEL_SELF_MANAGED_OPTIONS.length);

      VERIFICATION_LEVEL_SELF_MANAGED_OPTIONS.forEach((option, index) => {
        expect(suggestions.at(index).props('value')).toBe(option.text);
        expect(suggestions.at(index).text()).toContain(option.text);
      });
    });
  });

  describe('active level display', () => {
    it('displays the active level text when a value is selected', () => {
      window.gon = { dot_com: true };
      createComponent({ value: { data: 'GITLAB_MAINTAINED', operator: '=' } });

      expect(wrapper.text()).toContain('GitLab-maintained');
    });
  });
});
