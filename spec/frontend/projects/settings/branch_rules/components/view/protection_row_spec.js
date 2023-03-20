import { GlAvatarsInline, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectionRow, {
  MAX_VISIBLE_AVATARS,
  AVATAR_SIZE,
} from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import { protectionRowPropsMock } from './mock_data';

describe('Branch rule protection row', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ProtectionRow, {
      propsData: protectionRowPropsMock,
      stubs: { GlAvatarsInline },
    });
  };

  beforeEach(() => createComponent());

  const findTitle = () => wrapper.findByText(protectionRowPropsMock.title);
  const findAvatarsInline = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatarLinks = () => wrapper.findAllComponents(GlAvatarLink);
  const findAvatars = () => wrapper.findAllComponents(GlAvatar);
  const findAccessLevels = () => wrapper.findAllByTestId('access-level');
  const findApprovalsRequired = () =>
    wrapper.findByText(`${protectionRowPropsMock.approvalsRequired} approvals required`);
  const findStatusChecksUrl = () => wrapper.findByText(protectionRowPropsMock.statusCheckUrl);

  it('renders a title', () => {
    expect(findTitle().exists()).toBe(true);
  });

  it('renders an avatars-inline component', () => {
    expect(findAvatarsInline().props('avatars')).toMatchObject(protectionRowPropsMock.users);
    expect(findAvatarsInline().props('badgeSrOnlyText')).toBe('1 additional user');
  });

  it('renders avatar-link components', () => {
    expect(findAvatarLinks().length).toBe(MAX_VISIBLE_AVATARS);

    expect(findAvatarLinks().at(1).attributes('href')).toBe(protectionRowPropsMock.users[1].webUrl);
    expect(findAvatarLinks().at(1).attributes('title')).toBe(protectionRowPropsMock.users[1].name);
  });

  it('renders avatar components', () => {
    expect(findAvatars().length).toBe(MAX_VISIBLE_AVATARS);

    expect(findAvatars().at(1).attributes('src')).toBe(protectionRowPropsMock.users[1].avatarUrl);
    expect(findAvatars().at(1).attributes('label')).toBe(protectionRowPropsMock.users[1].name);
    expect(findAvatars().at(1).props('size')).toBe(AVATAR_SIZE);
  });

  it('renders access level descriptions', () => {
    expect(findAccessLevels().length).toBe(protectionRowPropsMock.accessLevels.length);

    expect(findAccessLevels().at(0).text()).toBe(
      protectionRowPropsMock.accessLevels[0].accessLevelDescription,
    );
    expect(findAccessLevels().at(1).text()).toContain(',');

    expect(findAccessLevels().at(1).text()).toContain(
      protectionRowPropsMock.accessLevels[1].accessLevelDescription,
    );
  });

  it('renders the number of approvals required', () => {
    expect(findApprovalsRequired().exists()).toBe(true);
  });

  it('renders status checks URL', () => {
    expect(findStatusChecksUrl().exists()).toBe(true);
  });
});
