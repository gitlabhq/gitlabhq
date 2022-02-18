import { GlModal, GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import RemoveClusterConfirmation from '~/clusters/components/remove_cluster_confirmation.vue';
import SplitButton from '~/vue_shared/components/split_button.vue';

describe('Remove cluster confirmation modal', () => {
  let wrapper;

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = mount(RemoveClusterConfirmation, {
      propsData: {
        clusterPath: 'clusterPath',
        clusterName: 'clusterName',
        ...props,
      },
      stubs,
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
    const findModal = () => wrapper.findComponent(GlModal);
    const findSplitButton = () => wrapper.findComponent(SplitButton);

    beforeEach(() => {
      createComponent({
        props: { clusterName: 'my-test-cluster' },
        stubs: { GlSprintf, GlModal: stubComponent(GlModal) },
      });
      jest.spyOn(findModal().vm, 'show').mockReturnValue();
    });

    it('opens modal with "cleanup" option', async () => {
      findSplitButton().vm.$emit('remove-cluster-and-cleanup');

      await nextTick();

      expect(findModal().vm.show).toHaveBeenCalled();
      expect(wrapper.vm.confirmCleanup).toEqual(true);
      expect(findModal().html()).toContain(
        '<strong>To remove your integration and resources, type <code>my-test-cluster</code> to confirm:</strong>',
      );
    });

    it('opens modal without "cleanup" option', async () => {
      findSplitButton().vm.$emit('remove-cluster');

      await nextTick();

      expect(findModal().vm.show).toHaveBeenCalled();
      expect(wrapper.vm.confirmCleanup).toEqual(false);
      expect(findModal().html()).toContain(
        '<strong>To remove your integration, type <code>my-test-cluster</code> to confirm:</strong>',
      );
    });

    describe('with cluster management project', () => {
      beforeEach(() => {
        createComponent({ props: { hasManagementProject: true } });
      });

      it('renders regular button instead', () => {
        expect(findSplitButton().exists()).toBe(false);
        expect(wrapper.find('[data-testid="btnRemove"]').exists()).toBe(true);
      });
    });
  });
});
