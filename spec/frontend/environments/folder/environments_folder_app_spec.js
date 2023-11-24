import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsFolderAppComponent from '~/environments/folder/environments_folder_app.vue';

describe('EnvironmentsFolderAppComponent', () => {
  let wrapper;
  const mockFolderName = 'folders';

  const createWrapper = () => {
    wrapper = shallowMountExtended(EnvironmentsFolderAppComponent, {
      propsData: {
        folderName: mockFolderName,
      },
    });
  };

  const findHeader = () => wrapper.findByTestId('folder-name');

  it('should render a header with the folder name', () => {
    createWrapper();

    expect(findHeader().text()).toMatchInterpolatedText(`Environments / ${mockFolderName}`);
  });
});
