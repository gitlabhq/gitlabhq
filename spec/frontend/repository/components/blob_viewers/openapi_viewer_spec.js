import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OpenapiViewer from '~/repository/components/blob_viewers/openapi_viewer.vue';
import renderOpenApi from '~/blob/openapi';

jest.mock('~/blob/openapi');

describe('OpenAPI Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = { rawPath: 'some/openapi.yml' };

  const createOpenApiViewer = () => {
    wrapper = shallowMountExtended(OpenapiViewer, {
      propsData: { blob: DEFAULT_BLOB_DATA },
    });
  };

  const findOpenApiViewer = () => wrapper.findByTestId('openapi');

  beforeEach(() => createOpenApiViewer());

  it('calls the openapi render', () => {
    expect(renderOpenApi).toHaveBeenCalledWith(wrapper.vm.$refs.viewer);
  });

  it('renders an openapi viewer', () => {
    expect(findOpenApiViewer().exists()).toBe(true);
    expect(findOpenApiViewer().attributes('data-endpoint')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
