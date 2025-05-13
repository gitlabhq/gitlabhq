import { shallowMount } from '@vue/test-utils';
import { GlLink, GlSprintf } from '@gitlab/ui';
import ProjectDelayedDeleteButton from '~/projects/components/project_delayed_delete_button.vue';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

jest.mock('lodash/uniqueId', () => () => 'fakeUniqueId');

describe('Project delayed delete modal', () => {
  let wrapper;

  const findSharedDeleteButton = () => wrapper.findComponent(SharedDeleteButton);

  const defaultProps = {
    delayedDeletionDate: '2020-12-12',
    confirmPhrase: 'foo',
    formPath: 'some/path',
    restoreHelpPath: 'recovery/help/path',
    isFork: false,
    issuesCount: 1,
    mergeRequestsCount: 2,
    forksCount: 3,
    starsCount: 4,
    buttonText: 'Delete project',
    nameWithNamespace: 'Foo / Bar',
  };

  const findLearnMoreLink = () => wrapper.findComponent(GlLink);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectDelayedDeleteButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        SharedDeleteButton,
      },
    });
  };

  describe('initialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Shows the learn more link', () => {
      expect(findLearnMoreLink().text()).toContain('Learn More');
      expect(findLearnMoreLink().attributes('href')).toBe(defaultProps.restoreHelpPath);
    });

    it('shows the restore message with date', () => {
      expect(wrapper.text()).toContain(
        `This project can be restored until ${defaultProps.delayedDeletionDate}`,
      );
    });

    it('passes correct props to shared delete button', () => {
      expect(findSharedDeleteButton().props()).toEqual({
        confirmPhrase: defaultProps.confirmPhrase,
        forksCount: defaultProps.forksCount,
        formPath: defaultProps.formPath,
        isFork: defaultProps.isFork,
        issuesCount: defaultProps.issuesCount,
        mergeRequestsCount: defaultProps.mergeRequestsCount,
        starsCount: defaultProps.starsCount,
        buttonText: defaultProps.buttonText,
        nameWithNamespace: defaultProps.nameWithNamespace,
      });
    });
  });
});
