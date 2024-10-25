import path from 'node:path';
import { readdir } from 'node:fs/promises';

const imagesPaths = [
  path.resolve(__dirname, '../..', 'app/assets/images'),
  path.resolve(__dirname, '../..', 'ee/app/assets/images'),
  path.resolve(__dirname, '../..', 'jh/app/assets/images'),
];

async function getAllFiles(dir, prependPath = '') {
  const result = [];
  let files = [];
  try {
    files = await readdir(dir, { withFileTypes: true });
    // eslint-disable-next-line no-empty
  } catch (e) {}

  for (const file of files) {
    const filePath = path.join(dir, file.name);

    if (file.isDirectory()) {
      // eslint-disable-next-line no-await-in-loop
      const nestedFiles = await getAllFiles(filePath, `${prependPath}${file.name}/`);
      result.push(...nestedFiles);
    } else {
      result.push(prependPath + file.name);
    }
  }

  return result;
}

export async function ImagesPlugin() {
  return {
    name: 'vite-plugin-gitlab-images',
    async config() {
      const [CEfiles, EEfiles, JHfiles] = await Promise.all(
        // eslint-disable-next-line no-return-await
        imagesPaths.map(async (imagesPath) => await getAllFiles(imagesPath)),
      );
      const [CEpath, EEpath, JHpath] = imagesPaths;
      const mappings = [
        [CEpath, CEfiles],
        [EEpath, EEfiles],
        [JHpath, JHfiles],
      ].reduce((acc, [filesPath, filenames]) => {
        filenames.forEach((filename) => {
          acc[filename] = path.resolve(filesPath, filename);
        });
        return acc;
      }, {});
      const alias = Object.keys(mappings).map((mapping) => {
        return {
          find: mapping,
          replacement: mappings[mapping],
        };
      });
      return {
        resolve: {
          alias,
        },
      };
    },
  };
}
