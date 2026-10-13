import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReleasesEmptyState from '~/releases/components/releases_empty_state.vue';

describe('releases_empty_state.vue', () => {
  const documentationPath = 'path/to/releases/documentation';
  const newReleasePath = 'path/to/releases/new-release';
  const illustrationPath = 'path/to/releases/empty/state/illustration';

  let wrapper;

  const createComponent = ({ canCreateRelease = true } = {}) => {
    wrapper = shallowMountExtended(ReleasesEmptyState, {
      provide: {
        documentationPath,
        illustrationPath,
        ...(canCreateRelease ? { newReleasePath } : {}),
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  it('renders a GlEmptyState and provides it with the correct props', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      title: ReleasesEmptyState.i18n.emptyStateTitle,
      svgPath: illustrationPath,
      description: ReleasesEmptyState.i18n.emptyStateText,
      primaryButtonLink: newReleasePath,
      primaryButtonText: ReleasesEmptyState.i18n.newRelease,
      secondaryButtonLink: documentationPath,
      secondaryButtonText: ReleasesEmptyState.i18n.releasesDocumentation,
    });
  });

  describe('when the user cannot create a release', () => {
    beforeEach(() => {
      createComponent({ canCreateRelease: false });
    });

    it('passes no primary button link, so GlEmptyState hides the button', () => {
      expect(findEmptyState().props('primaryButtonLink')).toBe(null);
    });
  });
});
