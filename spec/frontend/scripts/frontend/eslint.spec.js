/* eslint-disable no-console */
import { EventEmitter } from 'events';
import { spawn } from 'child_process';
import { runEslint } from '../../../../scripts/frontend/eslint';

jest.mock('child_process', () => ({
  spawn: jest.fn(),
}));

describe('ESLint Script', () => {
  let mockChildProcess;
  let originalExitCode;

  beforeEach(() => {
    // Save original process.exitCode
    originalExitCode = process.exitCode;

    // Setup process.argv mock
    process.argv = ['node', 'scripts/frontend/eslint.js', '.', '--fix'];

    // Mock console.log
    jest.spyOn(console, 'log').mockImplementation();

    // Create mock child process using Node's events module
    mockChildProcess = new EventEmitter();

    // Mock the spawn function to return our mock child process
    spawn.mockReturnValue(mockChildProcess);
  });

  afterEach(() => {
    // Restore all mocks and process.exitCode
    jest.restoreAllMocks();
    process.exitCode = originalExitCode;
  });

  describe('runEslint', () => {
    it('spawns eslint process with correct arguments', () => {
      runEslint();

      expect(spawn).toHaveBeenCalledWith('yarn', ['internal:eslint', '.', '--fix'], {
        stdio: 'inherit',
        name: 'ESLint',
      });
    });

    it('sets process.exitCode to 0 when eslint succeeds', () => {
      runEslint();

      // Emit a successful
      mockChildProcess.emit('close', 0);

      expect(process.exitCode).toBe(0);
      // Should not show any messages on success
      expect(console.log).toHaveBeenCalledTimes(0);
    });

    it('sets process.exitCode to non-zero when eslint fails', () => {
      runEslint();

      // Emit a failed exit
      mockChildProcess.emit('close', 1);

      expect(process.exitCode).toBe(1);
      // Should show info messages on failure
      expect(console.log).toHaveBeenCalledTimes(1);
    });

    it('shows GraphQL schema message in console when eslint fails', () => {
      runEslint();

      mockChildProcess.emit('close', 2);

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('GraphQL schema dump'));
    });

    it('passes all CLI arguments to eslint', () => {
      // Set custom CLI args
      process.argv = [
        'node',
        'scripts/frontend/eslint.js',
        'src/',
        '--quiet',
        '--max-warnings=0',
        '--format',
        'gitlab',
      ];

      runEslint();

      expect(spawn).toHaveBeenCalledWith(
        'yarn',
        ['internal:eslint', 'src/', '--quiet', '--max-warnings=0', '--format', 'gitlab'],
        expect.any(Object),
      );
    });
  });
});
