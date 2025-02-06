import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import ProjectDeleteButton from '~/projects/components/project_delete_button.vue';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

jest.mock('lodash/uniqueId', () => () => 'fakeUniqueId');

describe('Project remove modal', () => {
  let wrapper;

  const findSharedDeleteButton = () => wrapper.findComponent(SharedDeleteButton);

  const defaultProps = {
    confirmPhrase: 'foo',
    disabled: false,
    formPath: 'some/path',
    isFork: false,
    issuesCount: 1,
    mergeRequestsCount: 2,
    forksCount: 3,
    starsCount: 4,
    buttonText: 'Delete project',
    nameWithNamespace: 'Foo / Bar',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectDeleteButton, {
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

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('passes confirmPhrase and formPath props to the shared delete button', () => {
      expect(findSharedDeleteButton().props()).toEqual({
        confirmPhrase: defaultProps.confirmPhrase,
        disabled: defaultProps.disabled,
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
