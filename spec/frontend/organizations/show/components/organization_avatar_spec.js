import { GlAvatar, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import OrganizationAvatar from '~/organizations/show/components/organization_avatar.vue';
import {
  VISIBILITY_TYPE_ICON,
  ORGANIZATION_VISIBILITY_TYPE,
  VISIBILITY_LEVEL_PRIVATE_STRING,
} from '~/visibility_level/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('OrganizationAvatar', () => {
  let wrapper;

  const defaultPropsData = {
    organization: {
      id: 1,
      name: 'GitLab',
      visibility: VISIBILITY_LEVEL_PRIVATE_STRING,
    },
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(OrganizationAvatar, {
      propsData: defaultPropsData,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders avatar', () => {
    expect(wrapper.findComponent(GlAvatar).props()).toMatchObject({
      entityId: defaultPropsData.organization.id,
      entityName: defaultPropsData.organization.name,
    });
  });

  it('renders organization name', () => {
    expect(
      wrapper.findByRole('heading', { name: defaultPropsData.organization.name }).exists(),
    ).toBe(true);
  });

  it('renders visibility icon', () => {
    const icon = wrapper.findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]);
    expect(tooltip.value).toBe(ORGANIZATION_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]);
  });

  it('renders button to copy organization ID', () => {
    expect(wrapper.findComponent(ClipboardButton).props()).toMatchObject({
      category: 'tertiary',
      title: 'Copy organization ID',
      text: '1',
      size: 'small',
    });
  });
});
