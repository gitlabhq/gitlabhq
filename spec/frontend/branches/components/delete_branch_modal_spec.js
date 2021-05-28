import { GlButton, GlModal, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import DeleteBranchModal from '~/branches/components/delete_branch_modal.vue';

let wrapper;

const branchName = 'test_modal';

const createComponent = (data = {}) => {
  wrapper = shallowMount(DeleteBranchModal, {
    data() {
      return {
        branchName,
        deletePath: '/path/to/branch',
        defaultBranchName: 'default',
        ...data,
      };
    },
    attrs: {
      visible: true,
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        template:
          '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
      }),
      GlButton,
      GlFormInput,
    },
  });
};

const findDeleteButton = () => wrapper.find('[data-testid="delete_branch_confirmation_button"]');
const findFormInput = () => wrapper.findComponent(GlFormInput);

describe('Delete branch modal', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  describe('Deleting a regular branch', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal correctly', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('submits the form when clicked', () => {
      const submitFormSpy = jest.spyOn(wrapper.vm.$refs.form, 'submit');

      return wrapper.vm.$nextTick().then(() => {
        findDeleteButton().trigger('click');

        expect(submitFormSpy).toHaveBeenCalled();
      });
    });
  });

  describe('Deleting a protected branch (for owner or maintainer)', () => {
    beforeEach(() => {
      createComponent({ isProtectedBranch: true });
    });

    it('renders the modal correctly', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('disables the delete button when branch name input is unconfirmed', () => {
      expect(findDeleteButton().attributes('disabled')).toBe('true');
    });

    it('enables the delete button when branch name input is confirmed', () => {
      return wrapper.vm
        .$nextTick()
        .then(() => {
          findFormInput().vm.$emit('input', branchName);
        })
        .then(() => {
          expect(findDeleteButton()).not.toBeDisabled();
        });
    });
  });
});
