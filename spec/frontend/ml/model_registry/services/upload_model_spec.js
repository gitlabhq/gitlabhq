import axios from 'axios';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('uploadModel', () => {
  const importPath = 'some/path';
  const file = { name: 'file.txt', size: 1024 };
  const largeFile = { name: 'file.txt', size: 2024 };
  const maxAllowedFileSize = 2000;
  const baseFilePath = `${importPath}/${encodeURIComponent(file.name)}`;

  let axiosMock;
  beforeEach(() => {
    axiosMock = jest.spyOn(axios, 'put');
    axiosMock.mockImplementation(() => Promise.resolve({ status: HTTP_STATUS_OK }));
  });

  afterEach(() => {
    axiosMock.mockRestore();
  });

  it('should upload a file to the specified import path', async () => {
    await uploadModel({ importPath, file, maxAllowedFileSize });

    expect(axiosMock).toHaveBeenCalledTimes(1);
    expect(axiosMock).toHaveBeenCalledWith(baseFilePath, file, { onUploadProgress: undefined });
  });

  it('should upload a with a subfolder', async () => {
    const subfolder = 'action';
    const filePath = `${importPath}/action/${encodeURIComponent(file.name)}`;

    await uploadModel({ importPath, file, subfolder, maxAllowedFileSize });

    expect(axiosMock).toHaveBeenCalledTimes(1);
    expect(axiosMock).toHaveBeenCalledWith(filePath, file, { onUploadProgress: undefined });
  });

  it('should not upload when the subfolder contains spaces', async () => {
    const subfolder = 'sub folder';

    await expect(uploadModel({ importPath, file, subfolder, maxAllowedFileSize })).rejects.toThrow(
      new Error('Subfolder cannot contain spaces'),
    );
  });

  it('should not make a request if no file is provided', async () => {
    await uploadModel({ importPath });

    expect(axiosMock).not.toHaveBeenCalled();
  });

  it('should raise an error for large files', async () => {
    await expect(
      uploadModel({ importPath: 'some/path', file: largeFile, maxAllowedFileSize }),
    ).rejects.toThrow(
      new Error('File "file.txt" is 1.98 KiB. It is larger than max allowed size of 1.95 KiB'),
    );
  });

  it('accepts onUploadProgress', async () => {
    const onUploadProgress = jest.fn();
    await uploadModel({ importPath, file, maxAllowedFileSize, onUploadProgress });

    expect(axiosMock).toHaveBeenCalledWith(baseFilePath, file, { onUploadProgress });
  });

  it('accepts cancellation token and passes over to axios', async () => {
    const cancelToken = jest.fn();
    await uploadModel({
      importPath,
      file,
      maxAllowedFileSize,
      onUploadProgress: undefined,
      cancelToken,
    });

    expect(axiosMock).toHaveBeenCalledWith(baseFilePath, file, { undefined, cancelToken });
  });
});
