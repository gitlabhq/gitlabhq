import axios from 'axios';
import { uploadModel } from '~/ml/model_registry/services/upload_model';

describe('uploadModel', () => {
  let axiosMock;
  beforeEach(() => {
    axiosMock = jest.spyOn(axios, 'put');
    axiosMock.mockImplementation(() => Promise.resolve({ status: 200 }));
  });

  afterEach(() => {
    axiosMock.mockRestore();
  });

  const importPath = 'some/path';
  const file = { name: 'file.txt', size: 1024 };
  const filePath = `${importPath}/${encodeURIComponent(file.name)}`;

  it('should upload a file to the specified import path', async () => {
    await uploadModel({ importPath, file });

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
});
