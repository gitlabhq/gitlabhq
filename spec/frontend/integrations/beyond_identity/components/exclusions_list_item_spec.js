import { GlButton, GlIcon, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExclusionsListItem from '~/integrations/beyond_identity/components/exclusions_list_item.vue';
import { projectExclusionsMock } from './mock_data';

describe('ExclusionsListItem component', () => {
  let wrapper;
  const exclusion = projectExclusionsMock[0];

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findByText = (text) => wrapper.findByText(text);
  const findFindRemoveButton = () => wrapper.findComponent(GlButton);

  const createComponent = () =>
    shallowMountExtended(ExclusionsListItem, { propsData: { exclusion } });

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('default behavior', () => {
    it('renders an icon', () => {
      expect(findIcon().props('name')).toBe(exclusion.icon);
    });

    it('renders an avatar', () => {
      expect(findAvatar().props()).toMatchObject({
        alt: exclusion.name,
        entityName: exclusion.name,
        size: 32,
        shape: 'rect',
        src: exclusion.avatarUrl,
        fallbackOnError: true,
      });
    });

    it('renders a name', () => {
      expect(findByText(exclusion.name).exists()).toBe(true);
    });

    it('renders a remove button', () => {
      expect(findFindRemoveButton().attributes('aria-label')).toBe(
        `Remove exclusion for ${exclusion.name}`,
      );

      expect(findFindRemoveButton().props()).toMatchObject({
        icon: 'remove',
        category: 'tertiary',
      });
    });
  });

  describe('remove button', () => {
    it('emits remove event when clicked', () => {
      findFindRemoveButton().vm.$emit('click');

      expect(wrapper.emitted('remove')).toBeDefined();
    });
  });
});
