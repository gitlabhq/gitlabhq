var lineReader                    = require('../lib/line_reader'),
    assert                        = require('assert'),
    fs                            = require('fs'),
    testFilePath                  = __dirname + '/data/normal_file.txt',
    windowsFilePath               = __dirname + '/data/windows_file.txt',
    windowsBufferOverlapFilePath  = __dirname + '/data/windows_buffer_overlap_file.txt',
    unixFilePath                  = __dirname + '/data/unix_file.txt',
    macOs9FilePath                = __dirname + '/data/mac_os_9_file.txt',
    separatorFilePath             = __dirname + '/data/separator_file.txt',
    multiSeparatorFilePath        = __dirname + '/data/multi_separator_file.txt',
    multibyteFilePath             = __dirname + '/data/multibyte_file.txt',
    emptyFilePath                 = __dirname + '/data/empty_file.txt',
    oneLineFilePath               = __dirname + '/data/one_line_file.txt',
    oneLineFileNoEndlinePath      = __dirname + '/data/one_line_file_no_endline.txt',
    threeLineFilePath             = __dirname + '/data/three_line_file.txt',
    testSeparatorFile             = ['foo', 'bar\n', 'baz\n'],
    testFile = [
      'Jabberwocky',
      '',
      '’Twas brillig, and the slithy toves',
      'Did gyre and gimble in the wabe;',
      '',
      ''
    ],
    testBufferOverlapFile = [
      'test',
      'file'
    ];

describe("lineReader", function() {
  describe("eachLine", function() {
    it("should read lines using the default separator", function(done) {
      var i = 0;

      lineReader.eachLine(testFilePath, function(line, last) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 6) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(6, i);
        done();
      });
    });

    it("should read windows files by default", function(done) {
      var i = 0;

      lineReader.eachLine(windowsFilePath, function(line, last) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 6) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(6, i);
        done();
      });
    });

    it("should handle \\r\\n overlapping buffer window correctly", function(done) {
      var i = 0;
      var bufferSize = 5;

      lineReader.eachLine(windowsBufferOverlapFilePath, {bufferSize: bufferSize}, function(line, last) {
        assert.equal(testBufferOverlapFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 2) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(2, i);
        done();
      });
    });

    it("should read unix files by default", function(done) {
      var i = 0;

      lineReader.eachLine(unixFilePath, function(line, last) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 6) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(6, i);
        done();
      });
    });

    it("should read mac os 9 files by default", function(done) {
      var i = 0;

      lineReader.eachLine(macOs9FilePath, function(line, last) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 6) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(6, i);
        done();
      });
    });

    it("should allow continuation of line reading via a callback", function(done) {
      var i = 0;

      lineReader.eachLine(testFilePath, function(line, last, cb) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 6) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }

        process.nextTick(cb);
      }, function(err) {
        assert.ok(!err);
        assert.equal(6, i);
        done();
      });
    });

    it("should separate files using given separator", function(done) {
      var i = 0;
      lineReader.eachLine(separatorFilePath, {separator: ';'}, function(line, last) {
        assert.equal(testSeparatorFile[i], line);
        i += 1;
      
        if (i === 3) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(3, i);
        done();
      });
    });

    it("should separate files using given separator with more than one character", function(done) {
      var i = 0;
      lineReader.eachLine(multiSeparatorFilePath, {separator: '||'}, function(line, last) {
        assert.equal(testSeparatorFile[i], line);
        i += 1;
      
        if (i === 3) {
          assert.ok(last);
        } else {
          assert.ok(!last);
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(3, i);
        done();
      });
    });

    it("should allow early termination of line reading", function(done) {
      var i = 0;
      lineReader.eachLine(testFilePath, function(line, last) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 2) {
          return false;
        }
      }, function(err) {
        assert.ok(!err);
        assert.equal(2, i);
        done();
      });
    });

    it("should allow early termination of line reading via a callback", function(done) {
      var i = 0;
      lineReader.eachLine(testFilePath, function(line, last, cb) {
        assert.equal(testFile[i], line, 'Each line should be what we expect');
        i += 1;

        if (i === 2) {
          cb(false);
        } else {
          cb();
        }

      }, function(err) {
        assert.ok(!err);
        assert.equal(2, i);
        done();
      });
    });

    it("should not call callback on empty file", function(done) {
      lineReader.eachLine(emptyFilePath, function(line) {
        assert.ok(false, "Empty file should not cause any callbacks");
      }, function(err) {
        assert.ok(!err);
        done()
      });
    });

    it("should error when the user tries calls nextLine on a closed LineReader", function(done) {
      lineReader.open(oneLineFilePath, function(err, reader) {
        assert.ok(!err);
        reader.close(function(err) {
          assert.ok(!err);
          reader.nextLine(function(err, line) {
            assert.ok(err, "nextLine should have errored because the reader is closed");
            done();
          });
        });
      });
    });

    it("should work with a file containing only one line", function(done) {
      lineReader.eachLine(oneLineFilePath, function(line, last) {
        return true;
      }, function(err) {
        assert.ok(!err);
        done();
      });
    });

    it("should work with a file containing only one line and no endline character.", function(done) {
      var count = 0; var isDone = false;
      lineReader.eachLine(oneLineFileNoEndlinePath, function(line, last) {
        assert.equal(last, true, 'last should be true');
        return true;
      }, function(err) {
        assert.ok(!err);
        done();
      });
    });

    it("should close the file when eachLine finishes", function(done) {
      var reader;
      lineReader.eachLine(oneLineFilePath, function(line, last) {
        return false;
      }, function(err) {
        assert.ok(!err);
        assert.ok(reader.isClosed());
        done();
      }).getReader(function(_reader) {
        reader = _reader;
      });
    });

    it("should close the file if there is an error during eachLine", function(done) {
      lineReader.eachLine(testFilePath, {bufferSize: 10}, function(line, last) {
      }, function(err) {
        assert.equal('a test error', err.message);
        assert.ok(reader.isClosed());
        done();
      }).getReader(function(_reader) {
        reader = _reader;

        reader.getReadStream().read = function() {
          throw new Error('a test error');
        };
      });
    });
  });

  describe("open", function() {
    it("should return a reader object and allow calls to nextLine", function(done) {
      lineReader.open(testFilePath, function(err, reader) {
        assert.ok(!err);
        assert.ok(reader.hasNextLine());
      
        assert.ok(reader.hasNextLine(), 'Calling hasNextLine multiple times should be ok');
      
        reader.nextLine(function(err, line) {
          assert.ok(!err);
          assert.equal('Jabberwocky', line);
          assert.ok(reader.hasNextLine());
          reader.nextLine(function(err, line) {
            assert.ok(!err);
            assert.equal('', line);
            assert.ok(reader.hasNextLine());
            reader.nextLine(function(err, line) {
              assert.ok(!err);
              assert.equal('’Twas brillig, and the slithy toves', line);
              assert.ok(reader.hasNextLine());
              reader.nextLine(function(err, line) {
                assert.ok(!err);
                assert.equal('Did gyre and gimble in the wabe;', line);
                assert.ok(reader.hasNextLine());
                reader.nextLine(function(err, line) {
                  assert.ok(!err);
                  assert.equal('', line);
                  assert.ok(reader.hasNextLine());
                  reader.nextLine(function(err, line) {
                    assert.ok(!err);
                    assert.equal('', line);
                    assert.ok(!reader.hasNextLine());
                    reader.nextLine(function(err, line) {
                      assert.ok(err);
                      done();
                    });
                  });
                });
              });
            });
          });
        });
      });
    });

    it("should work with a file containing only one line", function(done) {
      lineReader.open(oneLineFilePath, function(err, reader) {
        assert.ok(!err);
        reader.close(function(err) {
          assert.ok(!err);
          done();
        });
      });
    });

    it("should read multibyte characters on the buffer boundary", function(done) {
      lineReader.open(multibyteFilePath, {separator: '\n', encoding: 'utf8', bufferSize: 2}, function(err, reader) {
        assert.ok(!err);
        assert.ok(reader.hasNextLine());
        reader.nextLine(function(err, line) {
          assert.ok(!err);
          assert.equal('ふうりうの初やおくの田植うた', line,
                       "Should read multibyte characters on buffer boundary");
          reader.close(function(err) {
            assert.ok(!err);
            done();
          });
        });
      });
    });

    it("should support opened streams", function() {
      var readStream = fs.createReadStream(testFilePath);

      lineReader.open(readStream, function(err, reader) {
        assert.ok(!err);
        assert.ok(reader.hasNextLine());
      
        assert.ok(reader.hasNextLine(), 'Calling hasNextLine multiple times should be ok');
      
        reader.nextLine(function(err, line) {
          assert.ok(!err);
          assert.equal('Jabberwocky', line);
        });
      });
    });

    it("should handle error while opening read stream", function() {
      lineReader.open('a file that does not exist', function(err, reader) {
        assert.ok(err);
        assert.ok(reader.isClosed());
      });
    });

    describe("hasNextLine", function() {
      it("should return true when buffer is empty but not at EOF", function(done) {
        lineReader.open(threeLineFilePath, {separator: '\n', encoding: 'utf8', bufferSize: 36}, function(err, reader) {
          assert.ok(!err);
          reader.nextLine(function(err, line) {
            assert.ok(!err);
            assert.equal("This is line one.", line);
            assert.ok(reader.hasNextLine());
            reader.nextLine(function(err, line) {
              assert.ok(!err);
              assert.equal("This is line two.", line);
              assert.ok(reader.hasNextLine());
              reader.nextLine(function(err, line) {
                assert.ok(!err);
                assert.equal("This is line three.", line);
                assert.ok(!reader.hasNextLine());
                reader.close(function(err) {
                  assert.ok(!err);
                  done();
                })
              });
            });
          });
        });
      });
    });
  });
});
