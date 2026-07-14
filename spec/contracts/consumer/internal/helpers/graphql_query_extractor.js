import { readFile } from 'fs/promises';
import path from 'path';

export async function extractGraphQLQuery(fileLocation) {
  const file = path.resolve(__dirname, '..', '..', '..', '..', fileLocation);

  return readFile(file, { encoding: 'UTF-8' });
}
