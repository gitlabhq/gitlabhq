import {
  groupNamespaces,
  userNamespaces,
} from 'jest/vue_shared/components/namespace_select/mock_data';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TransferProjectForm from '~/projects/settings/components/transfer_project_form.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';

describe('Transfer project form', () => {
  let wrapper;

  const confirmButtonText = 'Confirm';
  const confirmationPhrase = 'You must construct additional pylons!';

  const createComponent = () =>
    shallowMountExtended(TransferProjectForm, {
      propsData: {
        userNamespaces,
        groupNamespaces,
        confirmButtonText,
        confirmationPhrase,
      },
    });

  const findNamespaceSelect = () => wrapper.findComponent(NamespaceSelect);
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the namespace selector', () => {
    expect(findNamespaceSelect().exists()).toBe(true);
  });

  it('renders the confirm button', () => {
    expect(findConfirmDanger().exists()).toBe(true);
  });

  it('disables the confirm button by default', () => {
    expect(findConfirmDanger().attributes('disabled')).toBe('true');
  });

  describe('with a selected namespace', () => {
    const [selectedItem] = groupNamespaces;

    beforeEach(() => {
      findNamespaceSelect().vm.$emit('select', selectedItem);
    });

    it('emits the `selectNamespace` event when a namespace is selected', () => {
      const args = [selectedItem.id];

      expect(wrapper.emitted('selectNamespace')).toEqual([args]);
    });

    it('enables the confirm button', () => {
      expect(findConfirmDanger().attributes('disabled')).toBeUndefined();
    });

    it('clicking the confirm button emits the `confirm` event', () => {
      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toBeDefined();
    });
  });
});
