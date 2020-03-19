import sqljs from 'sql.js';
import axios from '~/lib/utils/axios_utils';
import BalsamiqViewer from '~/blob/balsamiq/balsamiq_viewer';
import ClassSpecHelper from '../../helpers/class_spec_helper';

jest.mock('sql.js');

describe('BalsamiqViewer', () => {
  const mockArrayBuffer = new ArrayBuffer(10);
  let balsamiqViewer;
  let viewer;

  describe('class constructor', () => {
    beforeEach(() => {
      viewer = {};

      balsamiqViewer = new BalsamiqViewer(viewer);
    });

    it('should set .viewer', () => {
      expect(balsamiqViewer.viewer).toBe(viewer);
    });
  });

  describe('loadFile', () => {
    let bv;
    const endpoint = 'endpoint';
    const requestSuccess = Promise.resolve({
      data: mockArrayBuffer,
      status: 200,
    });

    beforeEach(() => {
      viewer = {};
      bv = new BalsamiqViewer(viewer);
    });

    it('should call `axios.get` on `endpoint` param with responseType set to `arraybuffer', () => {
      jest.spyOn(axios, 'get').mockReturnValue(requestSuccess);
      jest.spyOn(bv, 'renderFile').mockReturnValue();

      bv.loadFile(endpoint);

      expect(axios.get).toHaveBeenCalledWith(
        endpoint,
        expect.objectContaining({
          responseType: 'arraybuffer',
        }),
      );
    });

    it('should call `renderFile` on request success', done => {
      jest.spyOn(axios, 'get').mockReturnValue(requestSuccess);
      jest.spyOn(bv, 'renderFile').mockImplementation(() => {});

      bv.loadFile(endpoint)
        .then(() => {
          expect(bv.renderFile).toHaveBeenCalledWith(mockArrayBuffer);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not call `renderFile` on request failure', done => {
      jest.spyOn(axios, 'get').mockReturnValue(Promise.reject());
      jest.spyOn(bv, 'renderFile').mockImplementation(() => {});

      bv.loadFile(endpoint)
        .then(() => {
          done.fail('Expected loadFile to throw error!');
        })
        .catch(() => {
          expect(bv.renderFile).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('renderFile', () => {
    let container;
    let previews;

    beforeEach(() => {
      viewer = {
        appendChild: jest.fn(),
      };
      previews = [document.createElement('ul'), document.createElement('ul')];

      balsamiqViewer = {
        initDatabase: jest.fn(),
        getPreviews: jest.fn(),
        renderPreview: jest.fn(),
      };
      balsamiqViewer.viewer = viewer;

      balsamiqViewer.getPreviews.mockReturnValue(previews);
      balsamiqViewer.renderPreview.mockImplementation(preview => preview);
      viewer.appendChild.mockImplementation(containerElement => {
        container = containerElement;
      });

      BalsamiqViewer.prototype.renderFile.call(balsamiqViewer, mockArrayBuffer);
    });

    it('should call .initDatabase', () => {
      expect(balsamiqViewer.initDatabase).toHaveBeenCalledWith(mockArrayBuffer);
    });

    it('should call .getPreviews', () => {
      expect(balsamiqViewer.getPreviews).toHaveBeenCalled();
    });

    it('should call .renderPreview for each preview', () => {
      const allArgs = balsamiqViewer.renderPreview.mock.calls;

      expect(allArgs.length).toBe(2);

      previews.forEach((preview, i) => {
        expect(allArgs[i][0]).toBe(preview);
      });
    });

    it('should set the container HTML', () => {
      expect(container.innerHTML).toBe('<ul></ul><ul></ul>');
    });

    it('should add inline preview classes', () => {
      expect(container.classList[0]).toBe('list-inline');
      expect(container.classList[1]).toBe('previews');
    });

    it('should call viewer.appendChild', () => {
      expect(viewer.appendChild).toHaveBeenCalledWith(container);
    });
  });

  describe('initDatabase', () => {
    let uint8Array;
    let data;

    beforeEach(() => {
      uint8Array = {};
      data = 'data';
      balsamiqViewer = {};
      window.Uint8Array = jest.fn();
      window.Uint8Array.mockReturnValue(uint8Array);

      BalsamiqViewer.prototype.initDatabase.call(balsamiqViewer, data);
    });

    it('should instantiate Uint8Array', () => {
      expect(window.Uint8Array).toHaveBeenCalledWith(data);
    });

    it('should call sqljs.Database', () => {
      expect(sqljs.Database).toHaveBeenCalledWith(uint8Array);
    });

    it('should set .database', () => {
      expect(balsamiqViewer.database).not.toBe(null);
    });
  });

  describe('getPreviews', () => {
    let database;
    let thumbnails;
    let getPreviews;

    beforeEach(() => {
      database = {
        exec: jest.fn(),
      };
      thumbnails = [{ values: [0, 1, 2] }];

      balsamiqViewer = {
        database,
      };

      jest.spyOn(BalsamiqViewer, 'parsePreview').mockImplementation(preview => preview.toString());
      database.exec.mockReturnValue(thumbnails);

      getPreviews = BalsamiqViewer.prototype.getPreviews.call(balsamiqViewer);
    });

    it('should call database.exec', () => {
      expect(database.exec).toHaveBeenCalledWith('SELECT * FROM thumbnails');
    });

    it('should call .parsePreview for each value', () => {
      const allArgs = BalsamiqViewer.parsePreview.mock.calls;

      expect(allArgs.length).toBe(3);

      thumbnails[0].values.forEach((value, i) => {
        expect(allArgs[i][0]).toBe(value);
      });
    });

    it('should return an array of parsed values', () => {
      expect(getPreviews).toEqual(['0', '1', '2']);
    });
  });

  describe('getResource', () => {
    let database;
    let resourceID;
    let resource;
    let getResource;

    beforeEach(() => {
      database = {
        exec: jest.fn(),
      };
      resourceID = 4;
      resource = ['resource'];

      balsamiqViewer = {
        database,
      };

      database.exec.mockReturnValue(resource);

      getResource = BalsamiqViewer.prototype.getResource.call(balsamiqViewer, resourceID);
    });

    it('should call database.exec', () => {
      expect(database.exec).toHaveBeenCalledWith(
        `SELECT * FROM resources WHERE id = '${resourceID}'`,
      );
    });

    it('should return the selected resource', () => {
      expect(getResource).toBe(resource[0]);
    });
  });

  describe('renderPreview', () => {
    let previewElement;
    let innerHTML;
    let preview;
    let renderPreview;

    beforeEach(() => {
      innerHTML = '<a>innerHTML</a>';
      previewElement = {
        outerHTML: '<p>outerHTML</p>',
        classList: {
          add: jest.fn(),
        },
      };
      preview = {};

      balsamiqViewer = {
        renderTemplate: jest.fn(),
      };

      jest.spyOn(document, 'createElement').mockReturnValue(previewElement);
      balsamiqViewer.renderTemplate.mockReturnValue(innerHTML);

      renderPreview = BalsamiqViewer.prototype.renderPreview.call(balsamiqViewer, preview);
    });

    it('should call classList.add', () => {
      expect(previewElement.classList.add).toHaveBeenCalledWith('preview');
    });

    it('should call .renderTemplate', () => {
      expect(balsamiqViewer.renderTemplate).toHaveBeenCalledWith(preview);
    });

    it('should set .innerHTML', () => {
      expect(previewElement.innerHTML).toBe(innerHTML);
    });

    it('should return element', () => {
      expect(renderPreview).toBe(previewElement);
    });
  });

  describe('renderTemplate', () => {
    let preview;
    let name;
    let resource;
    let template;
    let renderTemplate;

    beforeEach(() => {
      preview = { resourceID: 1, image: 'image' };
      name = 'name';
      resource = 'resource';
      template = `
        <div class="card">
          <div class="card-header">name</div>
          <div class="card-body">
            <img class="img-thumbnail" src="data:image/png;base64,image"/>
          </div>
        </div>
      `;

      balsamiqViewer = {
        getResource: jest.fn(),
      };

      jest.spyOn(BalsamiqViewer, 'parseTitle').mockReturnValue(name);
      balsamiqViewer.getResource.mockReturnValue(resource);

      renderTemplate = BalsamiqViewer.prototype.renderTemplate.call(balsamiqViewer, preview);
    });

    it('should call .getResource', () => {
      expect(balsamiqViewer.getResource).toHaveBeenCalledWith(preview.resourceID);
    });

    it('should call .parseTitle', () => {
      expect(BalsamiqViewer.parseTitle).toHaveBeenCalledWith(resource);
    });

    it('should return the template string', () => {
      expect(renderTemplate.replace(/\s/g, '')).toEqual(template.replace(/\s/g, ''));
    });
  });

  describe('parsePreview', () => {
    let preview;
    let parsePreview;

    beforeEach(() => {
      preview = ['{}', '{ "id": 1 }'];

      jest.spyOn(JSON, 'parse');

      parsePreview = BalsamiqViewer.parsePreview(preview);
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'parsePreview');

    it('should return the parsed JSON', () => {
      expect(parsePreview).toEqual(JSON.parse('{ "id": 1 }'));
    });
  });

  describe('parseTitle', () => {
    let title;
    let parseTitle;

    beforeEach(() => {
      title = { values: [['{}', '{}', '{"name":"name"}']] };

      jest.spyOn(JSON, 'parse');

      parseTitle = BalsamiqViewer.parseTitle(title);
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'parsePreview');

    it('should return the name value', () => {
      expect(parseTitle).toBe('name');
    });
  });
});
