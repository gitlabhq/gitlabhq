import { shallowMount } from '@vue/test-utils';
import ProjectDeleteButton from '~/projects/components/project_delete_button.vue';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

jest.mock('lodash/uniqueId', () => () => 'fakeUniqueId');

describe('Project remove modal', () => {
  let wrapper;

  const findSharedDeleteButton = () => wrapper.find(SharedDeleteButton);

  const defaultProps = {
    confirmPhrase: 'foo',
    formPath: 'some/path',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectDeleteButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        SharedDeleteButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('initialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('passes confirmPhrase and formPath props to the shared delete button', () => {
      expect(findSharedDeleteButton().props()).toEqual(defaultProps);
    });
  });
});
