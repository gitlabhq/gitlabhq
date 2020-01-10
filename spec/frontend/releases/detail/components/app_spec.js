import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import ReleaseDetailApp from '~/releases/detail/components/app';
import { release } from '../../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('Release detail component', () => {
  let wrapper;
  let releaseClone;
  let actions;
  let state;

  beforeEach(() => {
    gon.api_version = 'v4';

    releaseClone = JSON.parse(JSON.stringify(convertObjectPropsToCamelCase(release)));

    state = {
      release: releaseClone,
      markdownDocsPath: 'path/to/markdown/docs',
      updateReleaseApiDocsPath: 'path/to/update/release/api/docs',
    };

    actions = {
      fetchRelease: jest.fn(),
      updateRelease: jest.fn(),
      navigateToReleasesPage: jest.fn(),
    };

    const store = new Vuex.Store({ actions, state });

    wrapper = mount(ReleaseDetailApp, {
      store,
      attachToDocument: true,
    });

    return wrapper.vm.$nextTick();
  });

  it('calls fetchRelease when the component is created', () => {
    expect(actions.fetchRelease).toHaveBeenCalledTimes(1);
  });

  it('renders the description text at the top of the page', () => {
    expect(wrapper.find('.js-subtitle-text').text()).toBe(
      'Releases are based on Git tags. We recommend naming tags that fit within semantic versioning, for example v1.0, v2.0-pre.',
    );
  });

  it('renders the correct tag name in the "Tag name" field', () => {
    expect(wrapper.find('#git-ref').element.value).toBe(releaseClone.tagName);
  });

  it('renders the correct help text under the "Tag name" field', () => {
    const helperText = wrapper.find('#tag-name-help');
    const helperTextLink = helperText.find('a');
    const helperTextLinkAttrs = helperTextLink.attributes();

    expect(helperText.text()).toBe(
      'Changing a Release tag is only supported via Releases API. More information',
    );
    expect(helperTextLink.text()).toBe('More information');
    expect(helperTextLinkAttrs.href).toBe(state.updateReleaseApiDocsPath);
    expect(helperTextLinkAttrs.rel).toContain('noopener');
    expect(helperTextLinkAttrs.rel).toContain('noreferrer');
    expect(helperTextLinkAttrs.target).toBe('_blank');
  });

  it('renders the correct release title in the "Release title" field', () => {
    expect(wrapper.find('#release-title').element.value).toBe(releaseClone.name);
  });

  it('renders the release notes in the "Release notes" textarea', () => {
    expect(wrapper.find('#release-notes').element.value).toBe(releaseClone.description);
  });

  it('renders the "Save changes" button as type="submit"', () => {
    expect(wrapper.find('.js-submit-button').attributes('type')).toBe('submit');
  });

  it('calls updateRelease when the form is submitted', () => {
    wrapper.find('form').trigger('submit');
    expect(actions.updateRelease).toHaveBeenCalledTimes(1);
  });

  it('calls navigateToReleasesPage when the "Cancel" button is clicked', () => {
    wrapper.find('.js-cancel-button').vm.$emit('click');
    expect(actions.navigateToReleasesPage).toHaveBeenCalledTimes(1);
  });
});
