import { GlAvatarsInline, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectionRow, {
  MAX_VISIBLE_AVATARS,
  AVATAR_SIZE,
} from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import { protectionRowPropsMock, deployKeysMock } from './mock_data';

describe('Branch rule protection row', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ProtectionRow, {
      propsData: {
        ...protectionRowPropsMock,
        ...propsData,
        deployKeys: deployKeysMock,
      },
      stubs: { GlAvatarsInline },
    });
  };

  beforeEach(() => createComponent());

  const findTitle = () => wrapper.findByText(protectionRowPropsMock.title);
  const findAvatarsInline = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatarLinks = () => wrapper.findAllComponents(GlAvatarLink);
  const findAvatars = () => wrapper.findAllComponents(GlAvatar);
  const findAccessLevels = () => wrapper.findAllByTestId('access-level');
  const findSharedSecretBadge = () => wrapper.findByTestId('shared-secret');
  const findStatusChecksUrl = () => wrapper.findByText(protectionRowPropsMock.statusCheckUrl);
  const findDeployKeys = () => wrapper.findAllByTestId('deploy-key');

  it('renders a title', () => {
    expect(findTitle().exists()).toBe(true);
  });

  it('renders an avatars-inline component', () => {
    expect(findAvatarsInline().props('avatars')).toMatchObject([
      ...protectionRowPropsMock.users,
      ...protectionRowPropsMock.groups,
    ]);
    expect(findAvatarsInline().props('badgeSrOnlyText')).toBe('1 additional user');
    expect(findSharedSecretBadge().exists()).toBe(false);
  });

  it('renders avatar-link components', () => {
    expect(findAvatarLinks()).toHaveLength(MAX_VISIBLE_AVATARS);

    expect(findAvatarLinks().at(1).attributes('href')).toBe(protectionRowPropsMock.users[1].webUrl);
    expect(findAvatarLinks().at(1).attributes('title')).toBe(protectionRowPropsMock.users[1].name);
  });

  it('renders avatar components', () => {
    expect(findAvatars()).toHaveLength(MAX_VISIBLE_AVATARS);

    expect(findAvatars().at(1).attributes('src')).toBe(protectionRowPropsMock.users[1].avatarUrl);
    expect(findAvatars().at(1).attributes('label')).toBe(protectionRowPropsMock.users[1].name);
    expect(findAvatars().at(1).props('size')).toBe(AVATAR_SIZE);
  });

  it('renders access level descriptions', () => {
    expect(findAccessLevels()).toHaveLength(protectionRowPropsMock.accessLevels.length);

    expect(findAccessLevels().at(0).text()).toBe('Developers and Maintainers');

    expect(findAccessLevels().at(1).text()).toContain('Maintainers');
  });

  it('renders deploy keys badges', () => {
    expect(findDeployKeys()).toHaveLength(deployKeysMock.length);
    expect(findDeployKeys().at(0).text()).toBe('Deploy key 1');
  });

  it('renders status checks URL', () => {
    expect(findStatusChecksUrl().exists()).toBe(true);
  });

  it('renders status checks hmac enabled badge', () => {
    createComponent({
      propsData: {
        hmac: true,
      },
    });

    expect(findSharedSecretBadge().exists()).toBe(true);
  });
});
