import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarConfidentialityForm from '~/sidebar/components/confidential/sidebar_confidentiality_form.vue';
import { confidentialityQueries } from '~/sidebar/queries/constants';

jest.mock('~/alert');

describe('Sidebar Confidentiality Form', () => {
  let wrapper;

  const findWarningMessage = () => wrapper.find(`[data-testid="warning-message"]`);
  const findConfidentialToggle = () => wrapper.find(`[data-testid="confidential-toggle"]`);
  const findCancelButton = () => wrapper.find(`[data-testid="confidential-cancel"]`);

  const createComponent = ({
    props = {},
    mutate = jest.fn().mockResolvedValue('Success'),
  } = {}) => {
    wrapper = shallowMount(SidebarConfidentialityForm, {
      propsData: {
        fullPath: 'group/project',
        iid: '1',
        confidential: false,
        issuableType: 'issue',
        ...props,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const confidentialityMutation = (confidential, workspacePath) => {
    return {
      mutation: confidentialityQueries[wrapper.vm.issuableType].mutation,
      variables: {
        input: {
          confidential,
          iid: '1',
          ...workspacePath,
        },
      },
    };
  };

  const clickConfidentialToggle = () => {
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
  };

  it('emits a `closeForm` event when Cancel button is clicked', () => {
    createComponent();
    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted().closeForm).toHaveLength(1);
  });

  it('renders a loading state after clicking on turn on/off button', async () => {
    createComponent();
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));

    expect(wrapper.vm.$apollo.mutate).toHaveBeenCalled();
    await nextTick();
    expect(findConfidentialToggle().props('loading')).toBe(true);
  });

  it('creates an alert if mutation is rejected', async () => {
    createComponent({ mutate: jest.fn().mockRejectedValue('Error!') });
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while setting issue confidentiality.',
    });
  });

  it('creates an alert if mutation contains errors', async () => {
    createComponent({
      mutate: jest.fn().mockResolvedValue({
        data: { issuableSetConfidential: { errors: ['Houston, we have a problem!'] } },
      }),
    });
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Houston, we have a problem!',
    });
  });

  describe('when issue is not confidential', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a message about making an issue confidential', () => {
      expect(findWarningMessage().text()).toBe(
        'You are going to turn on confidentiality. Only project members with at least the Planner role, the author, and assignees can view or be notified about this issue.',
      );
    });

    it('has a `Turn on` button text', () => {
      expect(findConfidentialToggle().text()).toBe('Turn on');
    });

    it('calls a mutation to set confidential to true on button click', () => {
      clickConfidentialToggle();
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
        confidentialityMutation(true, { projectPath: 'group/project' }),
      );
    });
  });

  describe('when issue is confidential', () => {
    beforeEach(() => {
      createComponent({ props: { confidential: true } });
    });

    it('renders a message about making an issue non-confidential', () => {
      expect(findWarningMessage().text()).toBe(
        'You are going to turn off the confidentiality. This means everyone will be able to see and leave a comment on this issue.',
      );
    });

    it('has a `Turn off` button text', () => {
      expect(findConfidentialToggle().text()).toBe('Turn off');
    });

    it('calls a mutation to set confidential to false on button click', () => {
      findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: confidentialityQueries[wrapper.vm.issuableType].mutation,
        variables: {
          input: {
            confidential: false,
            iid: '1',
            projectPath: 'group/project',
          },
        },
      });
    });
  });

  describe('when issuable type is `epic`', () => {
    beforeEach(() => {
      createComponent({ props: { confidential: true, issuableType: 'epic' } });
    });

    it('renders a message about making an epic non-confidential', () => {
      expect(findWarningMessage().text()).toBe(
        'You are going to turn off the confidentiality. This means everyone will be able to see and leave a comment on this epic.',
      );
    });

    it('calls a mutation to set epic confidentiality with correct parameters', () => {
      clickConfidentialToggle();
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
        confidentialityMutation(false, { groupPath: 'group/project' }),
      );
    });
  });

  describe('when issuable type is `test_case`', () => {
    describe('when test case is confidential', () => {
      beforeEach(() => {
        createComponent({ props: { confidential: true, issuableType: 'test_case' } });
      });

      it('renders a message about making a test case non-confidential', () => {
        expect(findWarningMessage().text()).toBe(
          'You are going to turn off the confidentiality. This means everyone will be able to see this test case.',
        );
      });

      it('calls a mutation to set confidential to false on button click', () => {
        clickConfidentialToggle();
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          confidentialityMutation(false, { projectPath: 'group/project' }),
        );
      });
    });

    describe('when test case is not confidential', () => {
      beforeEach(() => {
        createComponent({ props: { issuableType: 'test_case' } });
      });

      it('renders a message about making a test case confidential', () => {
        expect(findWarningMessage().text()).toBe(
          'You are going to turn on confidentiality. Only project members with at least the Planner role can view or be notified about this test case.',
        );
      });

      it('calls a mutation to set confidential to true on button click', () => {
        clickConfidentialToggle();
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          confidentialityMutation(true, { projectPath: 'group/project' }),
        );
      });
    });
  });
});
