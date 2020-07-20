import { mount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import SplitButton from '~/vue_shared/components/split_button.vue';
import RemoveClusterConfirmation from '~/clusters/components/remove_cluster_confirmation.vue';

describe('Remove cluster confirmation modal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(RemoveClusterConfirmation, {
      propsData: {
        clusterPath: 'clusterPath',
        clusterName: 'clusterName',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders splitbutton with modal included', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('split button dropdown', () => {
    const findModal = () => wrapper.find(GlModal).vm;
    const findSplitButton = () => wrapper.find(SplitButton);

    beforeEach(() => {
      createComponent({ clusterName: 'my-test-cluster' });
      jest.spyOn(findModal(), 'show').mockReturnValue();
    });

    it('opens modal with "cleanup" option', () => {
      findSplitButton().vm.$emit('remove-cluster-and-cleanup');

      return wrapper.vm.$nextTick().then(() => {
        expect(findModal().show).toHaveBeenCalled();
        expect(wrapper.vm.confirmCleanup).toEqual(true);
      });
    });

    it('opens modal without "cleanup" option', () => {
      findSplitButton().vm.$emit('remove-cluster');

      return wrapper.vm.$nextTick().then(() => {
        expect(findModal().show).toHaveBeenCalled();
        expect(wrapper.vm.confirmCleanup).toEqual(false);
      });
    });

    describe('with cluster management project', () => {
      beforeEach(() => {
        createComponent({ hasManagementProject: true });
      });

      it('renders regular button instead', () => {
        expect(findSplitButton().exists()).toBe(false);
        expect(wrapper.find('[data-testid="btnRemove"]').exists()).toBe(true);
      });
    });
  });
});
