import { mount } from '@vue/test-utils';
import ReleaseBlock from '~/releases/components/release_block.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { first } from 'underscore';
import { release } from '../mock_data';

describe('Release block', () => {
  let wrapper;

  const factory = releaseProp => {
    wrapper = mount(ReleaseBlock, {
      propsData: {
        release: releaseProp,
      },
      sync: false,
    });
  };

  const milestoneListExists = () => wrapper.find('.js-milestone-list').exists();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default props', () => {
    beforeEach(() => {
      factory(release);
    });

    it("renders the block with an id equal to the release's tag name", () => {
      expect(wrapper.attributes().id).toBe('v0.3');
    });

    it('renders release name', () => {
      expect(wrapper.text()).toContain(release.name);
    });

    it('renders commit sha', () => {
      expect(wrapper.text()).toContain(release.commit.short_id);
    });

    it('renders tag name', () => {
      expect(wrapper.text()).toContain(release.tag_name);
    });

    it('renders release date', () => {
      expect(wrapper.text()).toContain(timeagoMixin.methods.timeFormated(release.released_at));
    });

    it('renders number of assets provided', () => {
      expect(wrapper.find('.js-assets-count').text()).toContain(release.assets.count);
    });

    it('renders dropdown with the sources', () => {
      expect(wrapper.findAll('.js-sources-dropdown li').length).toEqual(
        release.assets.sources.length,
      );

      expect(wrapper.find('.js-sources-dropdown li a').attributes().href).toEqual(
        first(release.assets.sources).url,
      );

      expect(wrapper.find('.js-sources-dropdown li a').text()).toContain(
        first(release.assets.sources).format,
      );
    });

    it('renders list with the links provided', () => {
      expect(wrapper.findAll('.js-assets-list li').length).toEqual(release.assets.links.length);

      expect(wrapper.find('.js-assets-list li a').attributes().href).toEqual(
        first(release.assets.links).url,
      );

      expect(wrapper.find('.js-assets-list li a').text()).toContain(
        first(release.assets.links).name,
      );
    });

    it('renders author avatar', () => {
      expect(wrapper.find('.user-avatar-link').exists()).toBe(true);
    });

    describe('external label', () => {
      it('renders external label when link is external', () => {
        expect(wrapper.find('.js-assets-list li a').text()).toContain('external source');
      });

      it('does not render external label when link is not external', () => {
        expect(wrapper.find('.js-assets-list li:nth-child(2) a').text()).not.toContain(
          'external source',
        );
      });
    });

    it('renders the milestone list if at least one milestone is associated to the release', () => {
      factory(release);

      expect(milestoneListExists()).toBe(true);
    });
  });

  it('does not render the milestone list if no milestones are associated to the release', () => {
    const releaseClone = JSON.parse(JSON.stringify(release));
    delete releaseClone.milestone;

    factory(releaseClone);

    expect(milestoneListExists()).toBe(false);
  });

  it('renders upcoming release badge', () => {
    const releaseClone = JSON.parse(JSON.stringify(release));
    releaseClone.upcoming_release = true;

    factory(releaseClone);

    expect(wrapper.text()).toContain('Upcoming Release');
  });
});
