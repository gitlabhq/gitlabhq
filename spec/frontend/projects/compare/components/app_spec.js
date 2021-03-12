import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CompareApp from '~/projects/compare/components/app.vue';
import RevisionCard from '~/projects/compare/components/revision_card.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const projectCompareIndexPath = 'some/path';
const refsProjectPath = 'some/refs/path';
const paramsFrom = 'master';
const paramsTo = 'master';

describe('CompareApp component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CompareApp, {
      propsData: {
        projectCompareIndexPath,
        refsProjectPath,
        paramsFrom,
        paramsTo,
        projectMergeRequestPath: '',
        createMrPath: '',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('renders component with prop', () => {
    expect(wrapper.props()).toEqual(
      expect.objectContaining({
        projectCompareIndexPath,
        refsProjectPath,
        paramsFrom,
        paramsTo,
      }),
    );
  });

  it('contains the correct form attributes', () => {
    expect(wrapper.attributes('action')).toBe(projectCompareIndexPath);
    expect(wrapper.attributes('method')).toBe('POST');
  });

  it('has input with csrf token', () => {
    expect(wrapper.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('has ellipsis', () => {
    expect(wrapper.find('[data-testid="ellipsis"]').exists()).toBe(true);
  });

  it('render Source and Target BranchDropdown components', () => {
    const revisionCards = wrapper.findAll(RevisionCard);

    expect(revisionCards.length).toBe(2);
    expect(revisionCards.at(0).props('revisionText')).toBe('Source');
    expect(revisionCards.at(1).props('revisionText')).toBe('Target');
  });

  describe('compare button', () => {
    const findCompareButton = () => wrapper.find(GlButton);

    it('renders button', () => {
      expect(findCompareButton().exists()).toBe(true);
    });

    it('submits form', () => {
      findCompareButton().vm.$emit('click');
      expect(wrapper.find('form').element.submit).toHaveBeenCalled();
    });

    it('has compare text', () => {
      expect(findCompareButton().text()).toBe('Compare');
    });
  });

  describe('merge request buttons', () => {
    const findProjectMrButton = () => wrapper.find('[data-testid="projectMrButton"]');
    const findCreateMrButton = () => wrapper.find('[data-testid="createMrButton"]');

    it('does not have merge request buttons', () => {
      createComponent();
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(false);
    });

    it('has "View open merge request" button', () => {
      createComponent({
        projectMergeRequestPath: 'some/project/merge/request/path',
      });
      expect(findProjectMrButton().exists()).toBe(true);
      expect(findCreateMrButton().exists()).toBe(false);
    });

    it('has "Create merge request" button', () => {
      createComponent({
        createMrPath: 'some/create/create/mr/path',
      });
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(true);
    });
  });
});
