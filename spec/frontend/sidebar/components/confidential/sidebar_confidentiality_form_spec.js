import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import SidebarConfidentialityForm from '~/sidebar/components/confidential/sidebar_confidentiality_form.vue';
import { confidentialityQueries } from '~/sidebar/constants';

jest.mock('~/flash');

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

  afterEach(() => {
    wrapper.destroy();
  });

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

  it('creates a flash if mutation is rejected', async () => {
    createComponent({ mutate: jest.fn().mockRejectedValue('Error!') });
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'Something went wrong while setting issue confidentiality.',
    });
  });

  it('creates a flash if mutation contains errors', async () => {
    createComponent({
      mutate: jest.fn().mockResolvedValue({
        data: { issuableSetConfidential: { errors: ['Houston, we have a problem!'] } },
      }),
    });
    findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'Houston, we have a problem!',
    });
  });

  describe('when issue is not confidential', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a message about making an issue confidential', () => {
      expect(findWarningMessage().text()).toBe(
        'You are going to turn on confidentiality. Only team members with at least Reporter access will be able to see and leave comments on the issue.',
      );
    });

    it('has a `Turn on` button text', () => {
      expect(findConfidentialToggle().text()).toBe('Turn on');
    });

    it('calls a mutation to set confidential to true on button click', () => {
      findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: confidentialityQueries[wrapper.vm.issuableType].mutation,
        variables: {
          input: {
            confidential: true,
            iid: '1',
            projectPath: 'group/project',
          },
        },
      });
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
      findConfidentialToggle().vm.$emit('click', new MouseEvent('click'));

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: confidentialityQueries[wrapper.vm.issuableType].mutation,
        variables: {
          input: {
            confidential: false,
            iid: '1',
            groupPath: 'group/project',
          },
        },
      });
    });
  });
});
