import { GlEmptyState, GlFormGroup, GlFormInputGroup, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ManifestsEmptyState from '~/packages_and_registries/dependency_proxy/components/manifests_empty_state.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('manifests empty state', () => {
  let wrapper;

  const provideDefaults = {
    noManifestsIllustration: 'noManifestsIllustration',
  };

  const createComponent = ({ stubs = {} } = {}) => {
    wrapper = shallowMountExtended(ManifestsEmptyState, {
      provide: provideDefaults,
      stubs: {
        GlEmptyState,
        GlFormInputGroup,
        ...stubs,
      },
    });
  };

  const findDocsLink = () => wrapper.findComponent(GlLink);
  const findEmptyTextDescription = () => wrapper.findAllComponents(GlSprintf).at(0);
  const findDocumentationTextDescription = () => wrapper.findAllComponents(GlSprintf).at(1);
  const findClipBoardButton = () => wrapper.findComponent(ClipboardButton);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    createComponent();
  });

  it('shows the empty state message', () => {
    expect(findEmptyState().props()).toMatchObject({
      svgPath: provideDefaults.noManifestsIllustration,
      title: ManifestsEmptyState.i18n.noManifestTitle,
    });
  });

  it('renders correct description', () => {
    expect(findEmptyTextDescription().attributes('message')).toBe(
      ManifestsEmptyState.i18n.emptyText,
    );
    expect(findDocumentationTextDescription().attributes('message')).toBe(
      ManifestsEmptyState.i18n.documentationText,
    );
  });

  it('renders a form group with a label', () => {
    expect(findFormGroup().attributes('label')).toBe(ManifestsEmptyState.i18n.codeExampleLabel);
    expect(findFormGroup().attributes('label-sr-only')).toBeDefined();
    expect(findFormGroup().attributes('label-for')).toBe('code-example');
  });

  it('renders a form input group', () => {
    createComponent({ stubs: { GlFormInputGroup: true } });

    expect(findFormInputGroup().exists()).toBe(true);
    expect(findFormInputGroup().attributes('id')).toBe('code-example');
    expect(findFormInputGroup().props('value')).toBe(ManifestsEmptyState.codeExample);
    expect(findFormInputGroup().attributes('readonly')).toBeDefined();
    expect(findFormInputGroup().props('selectOnClick')).toBe(true);
  });

  it('form input group has a clipboard button', () => {
    expect(findClipBoardButton().exists()).toBe(true);
    expect(findClipBoardButton().props()).toMatchObject({
      text: ManifestsEmptyState.codeExample,
      title: ManifestsEmptyState.i18n.copyExample,
    });
  });

  it('shows link to docs', () => {
    createComponent({ stubs: { GlSprintf } });

    expect(findDocsLink().attributes('href')).toBe(
      ManifestsEmptyState.links.DEPENDENCY_PROXY_HELP_PAGE_PATH,
    );
  });
});
