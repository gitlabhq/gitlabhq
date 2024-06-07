import axios from 'axios';
import { uploadModel } from '~/ml/model_registry/services/upload_model';

describe('uploadModel', () => {
  const importPath = 'some/path';
  const file = { name: 'file.txt', size: 1024 };
  const largeFile = { name: 'file.txt', size: 2024 };
  const maxAllowedFileSize = 2000;

  let axiosMock;
  beforeEach(() => {
    axiosMock = jest.spyOn(axios, 'put');
    axiosMock.mockImplementation(() => Promise.resolve({ status: 200 }));
  });

  afterEach(() => {
    axiosMock.mockRestore();
  });

  it('should upload a file to the specified import path', async () => {
    const filePath = `${importPath}/${encodeURIComponent(file.name)}`;

    await uploadModel({ importPath, file, maxAllowedFileSize });

    expect(axiosMock).toHaveBeenCalledTimes(1);
    expect(axiosMock).toHaveBeenCalledWith(filePath, expect.any(FormData), {
      headers: expect.objectContaining({
        'Content-Type': 'multipart/form-data',
      }),
    });
  });

  it('should upload a with a subfolder', async () => {
    const subfolder = 'action';
    const filePath = `${importPath}/action/${encodeURIComponent(file.name)}`;

    await uploadModel({ importPath, file, subfolder, maxAllowedFileSize });

    expect(axiosMock).toHaveBeenCalledTimes(1);
    expect(axiosMock).toHaveBeenCalledWith(filePath, expect.any(FormData), {
      headers: expect.objectContaining({
        'Content-Type': 'multipart/form-data',
      }),
    });
  });

  it('should not make a request if no file is provided', async () => {
    await uploadModel({ importPath: 'some/path' });

    expect(axiosMock).not.toHaveBeenCalled();
  });

  it('should raise an error for large files', async () => {
    await expect(
      uploadModel({ importPath: 'some/path', file: largeFile, maxAllowedFileSize }),
    ).rejects.toThrow(
      new Error('File "file.txt" is 1.98 KiB. It is larger than max allowed size of 1.95 KiB'),
    );
  });
});
