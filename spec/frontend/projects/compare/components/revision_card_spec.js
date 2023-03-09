import { shallowMount } from '@vue/test-utils';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';
import RevisionCard from '~/projects/compare/components/revision_card.vue';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown.vue';
import { revisionCardDefaultProps as defaultProps } from './mock_data';

describe('RepoDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RevisionCard, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const RevisionCardWrapper = () => wrapper.find('.revision-card');

  it('displays revision text', () => {
    expect(RevisionCardWrapper().text()).toContain(defaultProps.revisionText);
  });

  it('renders RepoDropdown component', () => {
    expect(wrapper.findAllComponents(RepoDropdown).exists()).toBe(true);
  });

  it('renders RevisionDropdown component', () => {
    expect(wrapper.findAllComponents(RevisionDropdown).exists()).toBe(true);
  });
});
