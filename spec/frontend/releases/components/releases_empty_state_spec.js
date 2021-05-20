import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReleasesEmptyState from '~/releases/components/releases_empty_state.vue';

describe('releases_empty_state.vue', () => {
  const documentationPath = 'path/to/releases/documentation';
  const illustrationPath = 'path/to/releases/empty/state/illustration';

  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ReleasesEmptyState, {
      provide: {
        documentationPath,
        illustrationPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a GlEmptyState and provides it with the correct props', () => {
    const emptyStateProps = wrapper.findComponent(GlEmptyState).props();

    expect(emptyStateProps).toEqual(
      expect.objectContaining({
        title: ReleasesEmptyState.i18n.emptyStateTitle,
        svgPath: illustrationPath,
      }),
    );
  });

  it('renders the empty state text', () => {
    expect(wrapper.findByText(ReleasesEmptyState.i18n.emptyStateText).exists()).toBe(true);
  });

  it('renders a link to the documentation', () => {
    const documentationLink = wrapper.findByText(ReleasesEmptyState.i18n.moreInformation);

    expect(documentationLink.exists()).toBe(true);

    expect(documentationLink.attributes()).toEqual(
      expect.objectContaining({
        'aria-label': ReleasesEmptyState.i18n.releasesDocumentation,
        href: documentationPath,
        target: '_blank',
      }),
    );
  });
});
