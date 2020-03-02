import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IssueCardInnerScopedLabel from '~/boards/components/issue_card_inner_scoped_label.vue';

describe('IssueCardInnerScopedLabel Component', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(IssueCardInnerScopedLabel, {
      propsData: {
        label: { title: 'Foo::Bar', description: 'Some Random Description' },
        labelStyle: { background: 'white', color: 'black' },
        scopedLabelsDocumentationLink: '/docs-link',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render label title', () => {
    expect(wrapper.find('.color-label').text()).toBe('Foo::Bar');
  });

  it('should render question mark symbol', () => {
    expect(wrapper.find('.fa-question-circle').exists()).toBe(true);
  });

  it('should render label style provided', () => {
    const label = wrapper.find('.color-label');

    expect(label.attributes('style')).toContain('background: white;');
    expect(label.attributes('style')).toContain('color: black;');
  });

  it('should render the docs link', () => {
    expect(wrapper.find(GlLink).attributes('href')).toBe('/docs-link');
  });
});
