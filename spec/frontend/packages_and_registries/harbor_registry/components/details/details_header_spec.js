import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DetailsHeader from '~/packages_and_registries/harbor_registry/components/details/details_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { ROOT_IMAGE_TEXT } from '~/packages_and_registries/harbor_registry/constants/index';

describe('Harbor Details Header', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findTitle = () => findByTestId('title');
  const findArtifactsCount = () => findByTestId('artifacts-count');

  const mountComponent = ({ propsData }) => {
    wrapper = shallowMount(DetailsHeader, {
      propsData,
      stubs: {
        TitleArea,
      },
    });
  };

  describe('artifact name', () => {
    describe('missing image name', () => {
      beforeEach(() => {
        mountComponent({ propsData: { imagesDetail: { name: '', artifactCount: 1 } } });
      });

      it('root image', () => {
        expect(findTitle().text()).toBe(ROOT_IMAGE_TEXT);
      });
    });

    describe('with artifact name present', () => {
      beforeEach(() => {
        mountComponent({ propsData: { imagesDetail: { name: 'shao/flinkx', artifactCount: 1 } } });
      });

      it('shows artifact.name', () => {
        expect(findTitle().text()).toContain('shao/flinkx');
      });
    });
  });

  describe('metadata items', () => {
    describe('artifacts count', () => {
      it('displays "-- artifacts" while loading', async () => {
        mountComponent({ propsData: { imagesDetail: {} } });
        await nextTick();

        expect(findArtifactsCount().props('text')).toBe('-- artifacts');
      });

      it('when there is more than one artifact has the correct text', async () => {
        mountComponent({ propsData: { imagesDetail: { name: 'shao/flinkx', artifactCount: 10 } } });

        await nextTick();

        expect(findArtifactsCount().props('text')).toBe('10 artifacts');
      });

      it('when there is one artifact has the correct text', async () => {
        mountComponent({
          propsData: { imagesDetail: { name: 'shao/flinkx', artifactCount: 1 } },
        });
        await nextTick();

        expect(findArtifactsCount().props('text')).toBe('1 artifact');
      });

      it('has the correct icon', async () => {
        mountComponent({
          propsData: { imagesDetail: { name: 'shao/flinkx', artifactCount: 1 } },
        });
        await nextTick();

        expect(findArtifactsCount().props('icon')).toBe('package');
      });
    });
  });
});
