import { shallowMount } from '@vue/test-utils';
import IssuableTitle from '~/boards/components/issuable_title.vue';

describe('IssuableTitle', () => {
  let wrapper;
  const defaultProps = {
    title: 'One',
    refPath: 'path',
  };
  const createComponent = () => {
    wrapper = shallowMount(IssuableTitle, {
      propsData: { ...defaultProps },
    });
  };
  const findIssueContent = () => wrapper.find('[data-testid="issue-title"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a title of an issue in the sidebar', () => {
    expect(findIssueContent().text()).toContain('One');
  });

  it('renders a referencePath of an issue in the sidebar', () => {
    expect(findIssueContent().text()).toContain('path');
  });
});
