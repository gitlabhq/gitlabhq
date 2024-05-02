import { nextTick } from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExclusionsList from '~/integrations/beyond_identity/components/exclusions_list.vue';
import AddExclusionsDrawer from '~/integrations/beyond_identity/components/add_exclusions_drawer.vue';
import ExclusionsTabs from '~/integrations/beyond_identity/components/exclusions_tabs.vue';
import ExclusionsListItem from '~/integrations/beyond_identity/components/exclusions_list_item.vue';
import ConfirmRemovalModal from '~/integrations/beyond_identity/components/remove_exclusion_confirmation_modal.vue';
import showToast from '~/vue_shared/plugins/global_toast';
import { projectExclusionsMock } from './mock_data';

jest.mock('~/vue_shared/plugins/global_toast');

describe('ExclusionsList component', () => {
  let wrapper;

  const findTabs = () => wrapper.findComponent(ExclusionsTabs);
  const findListItems = () => wrapper.findAllComponents(ExclusionsListItem);
  const findConfirmRemoveModal = () => wrapper.findComponent(ConfirmRemovalModal);
  const findByText = (text) => wrapper.findByText(text);
  const findAddExclusionsButton = () => findByText('Add exclusions');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDrawer = () => wrapper.findComponent(AddExclusionsDrawer);

  const createComponent = () => shallowMountExtended(ExclusionsList);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('default behavior', () => {
    it('renders tabs', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders help text', () => {
      expect(
        findByText(
          'Groups and projects in this list no longer require commits to be signed.',
        ).exists(),
      ).toBe(true);
    });

    it('renders an Add exclusions button', () => {
      expect(findAddExclusionsButton().exists()).toBe(true);
    });

    it('renders an Empty state', () => {
      expect(findEmptyState().props('title')).toBe('There are no exclusions');
    });

    it('does not render an open drawer', () => {
      expect(findDrawer().props('isOpen')).toBe(false);
    });
  });

  describe('adding Exclusions', () => {
    beforeEach(() => findAddExclusionsButton().vm.$emit('click'));

    it('opens a drawer', () => {
      expect(findDrawer().props('isOpen')).toBe(true);
    });

    describe('Exclusions added', () => {
      beforeEach(() => findDrawer().vm.$emit('add', projectExclusionsMock));

      it('lists the added exclusions, sorted by type', async () => {
        await nextTick();

        expect(findListItems().at(0).props('exclusion')).toMatchObject(projectExclusionsMock[0]);
        expect(findListItems().at(1).props('exclusion')).toMatchObject(projectExclusionsMock[1]);
      });

      it('closes the drawer', () => {
        expect(findDrawer().props('isOpen')).toBe(false);
      });
    });
  });

  describe('removing Exclusions', () => {
    beforeEach(async () => {
      findAddExclusionsButton().vm.$emit('click');
      findDrawer().vm.$emit('add', projectExclusionsMock);
      await nextTick();
      findListItems().at(1).vm.$emit('remove');
    });

    it('opens a confirmation modal', () => {
      expect(findConfirmRemoveModal().props()).toMatchObject({
        name: 'project bar',
        type: 'project',
        visible: true,
      });
    });

    describe('confirmation modal primary action', () => {
      beforeEach(() => findConfirmRemoveModal().vm.$emit('primary'));

      it('removes the exclusion', () => {
        expect(findListItems().length).toBe(1);
      });

      it('renders a toast', () => {
        expect(showToast).toHaveBeenCalledWith('Project exclusion removed', {
          action: {
            text: 'Undo',
            onClick: expect.any(Function),
          },
        });
      });
    });
  });
});
