import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReleasesEmptyState from '~/releases/components/releases_empty_state.vue';

describe('releases_empty_state.vue', () => {
  const documentationPath = 'path/to/releases/documentation';
  const newReleasePath = 'path/to/releases/new-release';
  const illustrationPath = 'path/to/releases/empty/state/illustration';

  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ReleasesEmptyState, {
      provide: {
        documentationPath,
        newReleasePath,
        illustrationPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a GlEmptyState and provides it with the correct props', () => {
    const emptyStateProps = wrapper.findComponent(GlEmptyState).props();

    expect(emptyStateProps).toMatchObject({
      title: ReleasesEmptyState.i18n.emptyStateTitle,
      svgPath: illustrationPath,
      description: ReleasesEmptyState.i18n.emptyStateText,
      primaryButtonLink: newReleasePath,
      primaryButtonText: ReleasesEmptyState.i18n.newRelease,
      secondaryButtonLink: documentationPath,
      secondaryButtonText: ReleasesEmptyState.i18n.releasesDocumentation,
    });
  });
});
